# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

Dotenv.load

BASE_QUERY_URL = ENV['LIBGEN_BASE_QUERY_URL']
DOWNLOAD_DIR = ENV['DOWNLOAD_FOLDER'] || 'books_downloaded'

Dir.mkdir(DOWNLOAD_DIR) unless Dir.exist?(DOWNLOAD_DIR)
