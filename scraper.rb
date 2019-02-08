#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def idify
    downcase.gsub(/\s+/, '_')
  end
end

class MembersList < Scraped::HTML
  field :members do
    noko.xpath('.//table[.//td[contains(.,"CIRCONSCRIPTION")]]//tr').drop(1).map { |tr| fragment(tr => Member).to_h }
  end
end

class Member < Scraped::HTML
  field :id do
    name.idify
  end

  field :name do
    tds[0].text.tidy
  end

  field :area do
    tds[1].text.tidy
  end

  field :party do
    tds[2].text.tidy
  end

  field :term do
    2018
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'http://www.assemblee-nationale.tg/index.php?option=com_content&view=article&id=174&Itemid=1246'
Scraped::Scraper.new(url => MembersList).store(:members)
