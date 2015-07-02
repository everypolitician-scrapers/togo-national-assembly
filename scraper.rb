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

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#jsn-mainbody table tbody tr').each do |mp|
    tds = mp.css('td')
    data = { 
      name: tds[0].text.strip,
      party: tds[1].text.strip,
      area: tds[2].text.strip,
      term: 2013,
      source: url,
    }
    puts data
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
