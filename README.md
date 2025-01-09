# The Real E-Reader

This project is a Ruby script to search for books on LibGen, filter by EPUB or PDF format, and download them for personal use.

## Features
- Search for a book by title
- Automatically select and download the first result (or let you choose a book manually by uncommenting specific lines).
- Filters search results to include only EPUB or PDF formats
- Downloads books to the `books_downloaded` folder
- TODO: Send book to E-Reader (kindle)

## Installation

1. Clone this repository:
```bash
  git clone <repository_url>
  cd the_real_e_reader
```

2. Install dependencies:
```bash
  bundle install
```

3. Create an `.env` file:
```bash
  cp .env.copy .env
```

## Usage
Run the script with:

```bash
  ruby the_real_e_reader_script.rb
```

Test the script:

```bash
  rspec
```
