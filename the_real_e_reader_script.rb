# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)
require 'open-uri'

BASE_QUERY_URL = ENV['LIBGEN_BASE_QUERY_URL']

# Comment in f/ Terminal Usage
# puts 'Enter the book title you want to search for:'
# book_title = gets.chomp
book_title = 'The Neverending Story'
puts "Searching for: #{book_title} 🔍"

search_url = "#{BASE_QUERY_URL}&req=#{URI.encode_www_form_component(book_title)}"
search_page = URI.open(search_url)
doc = Nokogiri::HTML(search_page)
rows = doc.css('table.c > tr').drop(1)

# Extract book details
books = rows.map do |row|
  id = row.css('td:nth-child(1)').text.strip
  author = row.css('td:nth-child(2)').text.strip
  title = row.css('td:nth-child(3)').text.strip
  year = row.css('td:nth-child(5)').text.strip
  size = row.css('td:nth-child(8)').text.strip
  format = row.css('td:nth-child(9)').text.strip.downcase
  mirrors = row.css('td:nth-child(10) a').map { |a| a['href'] }

  { id: id, author: author, title: title, year: year, size: size, format: format, mirrors: mirrors }
end

# Filter books to include only EPUB or PDF formats
book_links = books.filter do |book|
  book[:format].include?('epub') || book[:format].include?('pdf')
end

if book_links.empty?
  puts "No EPUB or PDF files found for '#{book_title}'."
else
  book_links.each_with_index do |book, index|
    puts "[#{index + 1}] #{book[:title]} by #{book[:author]} (#{book[:year]}) - #{book[:size]} - Format: #{book[:format]}"
  end

  # Comment in f/ Terminal Usage
  # puts 'Enter the number of the book you want to download and send to your Kindle:'
  # choice = gets.chomp.to_i - 1
  # selected_book = book_links[choice]
  selected_book = book_links.first
  puts "Automatically selected: #{selected_book[:title]} by #{selected_book[:author]}"

  file_name = "#{selected_book[:title].gsub(/[\\\/:*?\"<>|]/, '_')}.#{selected_book[:format]}"
  file_downloaded = false

  selected_book[:mirrors].each do |mirror_url|
    mirror_url = mirror_url.sub('library.gift', 'libgen.is')
    puts "Attempting download from: #{mirror_url}"

    begin
      content = URI.open(mirror_url).read
      File.open(file_name, 'wb') { |file| file.write(content) }
      puts "Downloaded file saved as #{file_name}."
      file_downloaded = true
      break
    rescue OpenURI::HTTPError => e
      puts "HTTP error for mirror #{mirror_url}: #{e.message}"
    rescue SocketError => e
      puts "Network error for mirror #{mirror_url}: #{e.message}"
    end
  end

  puts 'Failed to download the file from all mirrors. Please try a different book.' unless file_downloaded
end
