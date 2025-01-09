# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'
Bundler.require(:default)

require_relative '../lib/the_real_e_reader_script'

RSpec.describe 'The Real E-Reader Script' do # rubocop:disable Metrics/BlockLength
  let(:search_url) do
    query_params = { lg_topic: 'libgen', open: 0, view: 'simple', res: 25, phrase: 1, column: 'def',
                     req: 'The Neverending Story' }
    "#{BASE_QUERY_URL}?#{URI.encode_www_form(query_params)}"
  end
  let(:book_page_url) { 'https://www.libgen.is/book/index.php?md5=453CF1E078A62D9E5589BE5B0DE527BE' }
  let(:download_link) { 'http://library.gift/main/453CF1E078A62D9E5589BE5B0DE527BE' }
  let(:download_dir) { 'books_downloaded' }

  before do
    stub_request(:get, search_url).to_return(status: 200, body: File.read('spec/fixtures/libgen_search_results.html'))
    stub_request(:get, book_page_url).to_return(status: 200, body: File.read('spec/fixtures/libgen_book_page.html'))
    stub_request(:get, download_link).to_return(status: 200, body: 'Mock EPUB Content')
  end

  after do
    # Cleanup all files in the download directory
    Dir.glob("#{download_dir}/*").each { |file| File.delete(file) if File.file?(file) }
  end

  describe 'fetching and parsing search results' do
    it 'returns parsed book links' do
      response = HTTParty.get(search_url)
      doc = Nokogiri::HTML(response.body)
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
  end

  describe 'fetching and parsing a book-specific page' do
    it 'returns valid download links' do
      response = HTTParty.get(book_page_url)
      doc = Nokogiri::HTML(response.body)
      download_links = doc.css('a[href]').map { |a| a['href'] }.select do |url|
        url.include?('main') || url.include?('download') || url.include?('get')
      end

      expect(download_links).to include(download_link)
    end
  end

  describe 'downloading a file' do
    it 'saves the file to the system' do
      file_name = "#{download_dir}/The_Neverending_Story.pdf"
      response = HTTParty.get(download_link)

      File.open(file_name, 'wb') { |file| file.write(response.body) }

      expect(File.exist?(file_name)).to be true
      expect(File.read(file_name)).to eq('Mock EPUB Content')
    end
  end
end
