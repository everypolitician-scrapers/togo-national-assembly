#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'
require 'pry'

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
    prefix, name = remove_prefixes(tds[0].text.gsub(/[[:space:]]+/, ' ').strip)
    next if name.to_s.empty?
    data = { 
      name: name,
      honorific_prefix: prefix,
      party: tds[1].text.strip,
      area: tds[2].text.strip,
      gender: gender_from(prefix),
      term: 2013,
    }
    # puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

term = {
  id: '2013',
  name: '2013–',
  start_date: '2013',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.assemblee-nationale.tg/index.php?option=com_content&view=article&id=174&Itemid=1246')
