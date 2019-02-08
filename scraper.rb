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
    noko.css('#jsn-mainbody table tbody tr').map { |td| fragment(td => Member).to_h }
  end
end

class Member < Scraped::HTML
  field :id do
    fullname.idify
  end

  field :name do
    nameparts.last
  end

  field :honorific_prefix do
    nameparts.first
  end

  field :sort_name do
    name
  end

  field :party do
    tds[1].text.strip
  end

  field :area do
    tds[2].text.strip
  end

  field :gender do
    return 'female' if honorific_prefix == 'Mme'
    return 'male'   if honorific_prefix == 'M'

    raise "Unknown gender for #{honorific_prefix}"
  end

  field :term do
    2013
  end

  private

  def tds
    noko.css('td')
  end

  def fullname
    tds[0].text.gsub(/[[:space:]]+/, ' ').strip
  end

  def nameparts
    name = fullname.dup
    return ['Mme', name] if name.sub! /^Mme\.?\s/, ''
    return ['M', name] if name.sub! /^M[\. ]+/, ''

    return
  end
end

url = 'http://www.assemblee-nationale.tg/index.php?option=com_content&view=article&id=174&Itemid=1246'
Scraped::Scraper.new(url => MembersList).store(:members)
