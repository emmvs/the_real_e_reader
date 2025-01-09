# frozen_string_literal: true

require_relative '../config/environment'

def search_and_download(book_title)
  puts "Searching for: #{book_title} 🔍"

  search_url = "#{BASE_QUERY_URL}&req=#{URI.encode_www_form_component(book_title)}"
  response = HTTParty.get(search_url)

  if response.code == 200
    doc = Nokogiri::HTML(response.body)
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

    book_links = books.select { |book| %w[epub pdf].include?(book[:format]) }

    if book_links.empty?
      puts "No EPUB or PDF files found for '#{book_title}'."
    else
      book_links.each_with_index do |book, index|
        puts "[#{index + 1}] #{book[:title]} by #{book[:author]} (#{book[:year]}) - #{book[:size]} - Format: #{book[:format]}"
      end

      puts 'Enter the number of the book you want to download:' if $PROGRAM_NAME == __FILE__
      choice = $PROGRAM_NAME == __FILE__ ? gets.chomp.to_i - 1 : 0
      selected_book = book_links[choice]

      puts "Automatically selected: #{selected_book[:title]} by #{selected_book[:author]}" if choice.zero?

      file_name = "#{DOWNLOAD_DIR}/#{selected_book[:title].gsub(%r{[\\/:*?"<>|]}, '_')}.#{selected_book[:format]}"
      file_downloaded = false

      selected_book[:mirrors].each do |mirror_url|
        mirror_url = mirror_url.sub('library.gift', 'libgen.is')
        puts "Attempting download from: #{mirror_url}"

        begin
          content = HTTParty.get(mirror_url).body
          File.open(file_name, 'wb') { |file| file.write(content) }
          puts "Downloaded file saved as #{file_name}."
          file_downloaded = true
          break
        rescue StandardError => e
          puts "Error for mirror #{mirror_url}: #{e.message}"
        end
      end

      puts 'Failed to download the file from all mirrors. Please try a different book.' unless file_downloaded
    end
  else
    puts "Failed to fetch search results. HTTP Status: #{response.code}"
  end
end

# Main execution
if $PROGRAM_NAME == __FILE__
  puts 'Enter the book title you want to search for:'
  book_title = gets.chomp
  search_and_download(book_title)
end
