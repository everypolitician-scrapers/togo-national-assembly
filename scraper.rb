#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def idify
    downcase.gsub(/\s+/, '_')
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def gender_from(prefix)
  return 'female' if prefix == 'Mme'
  return 'male'   if prefix == 'M'
  raise "Unknown gender for #{prefix}"
end

def remove_prefixes(name)
  return ['Mme', name] if name.sub! /^Mme\.?\s/, ''
  return ['M', name] if name.sub! /^M[\. ]+/, ''
  return
end

def member_data(url)
  noko = noko_for(url)
  noko.css('#jsn-mainbody table tbody tr').map do |mp|
    tds = mp.css('td')
    fullname = tds[0].text.gsub(/[[:space:]]+/, ' ').strip
    prefix, name = remove_prefixes(fullname.dup)
    next if name.to_s.empty?
    {
      id:               fullname.idify,
      name:             name,
      honorific_prefix: prefix,
      sort_name:        name,
      party:            tds[1].text.strip,
      area:             tds[2].text.strip,
      gender:           gender_from(prefix),
      term:             2013,
    }
  end
end

data = member_data('http://www.assemblee-nationale.tg/index.php?option=com_content&view=article&id=174&Itemid=1246').compact
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[name term], data)
