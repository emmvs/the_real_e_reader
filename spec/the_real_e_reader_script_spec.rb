# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
require 'nokogiri'
require 'open-uri'
require 'dotenv/load'

require_relative '../the_real_e_reader_script'

describe 'The Real E-Reader Script' do # rubocop:disable Metrics/BlockLength
  let(:search_url) { "#{BASE_QUERY_URL}&req=The+Neverending+Story" }
  let(:book_page_url) { "https://www.libgen.is/book/index.php?md5=453CF1E078A62D9E5589BE5B0DE527BE" }
  let(:download_link) { "http://library.gift/main/453CF1E078A62D9E5589BE5B0DE527BE" }

  before do
    stub_request(:get, search_url).to_return(status: 200, body: File.read('spec/fixtures/libgen_search_results.html'))
    stub_request(:get, book_page_url).to_return(status: 200, body: File.read('spec/fixtures/libgen_book_page.html'))
    stub_request(:get, download_link).to_return(status: 200, body: 'Mock EPUB Content')
  end

  it 'fetches and parses search results' do
    search_page = URI.open(search_url)
    doc = Nokogiri::HTML(search_page)
    book_links = doc.css('table.c > tr').drop(1).map do |row|
      {
        id: row.css('td:nth-child(1)').text.strip,
        author: row.css('td:nth-child(2)').text.strip,
        title: row.css('td:nth-child(3)').text.strip,
        year: row.css('td:nth-child(5)').text.strip,
        size: row.css('td:nth-child(8)').text.strip,
        format: row.css('td:nth-child(9)').text.strip.downcase,
        mirrors: row.css('td:nth-child(10) a').map { |a| "https://www.libgen.is/#{a['href']}" }
      }
    end

    expect(book_links).not_to be_empty
    expect(book_links.first[:title]).to include('The Neverending Story')
  end

  it 'fetches and parses book-specific page' do
    book_page = URI.open(book_page_url)
    doc = Nokogiri::HTML(book_page)
    download_links = doc.css('a[href]').map { |a| a['href'] }.select do |url|
      url.include?('main') || url.include?('download') || url.include?('get')
    end

    expect(download_links).to include(download_link)
  end

  it 'downloads the file from a valid link' do
    file_name = 'The_Neverending_Story.epub'
    File.open(file_name, 'wb') do |file|
      file.write URI.open(download_link).read
    end

    expect(File.exist?(file_name)).to be true
    expect(File.read(file_name)).to eq('Mock EPUB Content')

    File.delete(file_name)
  end
end
