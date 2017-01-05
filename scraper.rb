#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

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
  binding.pry
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#jsn-mainbody table tbody tr').each do |mp|
    tds = mp.css('td')
    fullname = tds[0].text.gsub(/[[:space:]]+/, ' ').strip
    prefix, name = remove_prefixes(fullname.dup)
    next if name.to_s.empty?
    data = {
      name:             fullname,
      honorific_prefix: prefix,
      sort_name:        name,
      party:            tds[1].text.strip,
      area:             tds[2].text.strip,
      gender:           gender_from(prefix),
      term:             2013,
    }
    ScraperWiki.save_sqlite(%i(name term), data)
  end
end

scrape_list('http://www.assemblee-nationale.tg/index.php?option=com_content&view=article&id=174&Itemid=1246')
