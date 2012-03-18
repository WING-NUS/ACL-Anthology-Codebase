#!/usr/bin/env ruby

puts "anthoTitleAuthorsPairs2Bibs.rb"
puts "Requires Ruby 1.9.x"
puts "Created by Jesse Gozali, Dec 11th 2011"
puts ""
puts "Please modify the constants in-file before running the program."
puts "Press Enter to proceed"

$stdin.gets
$stdin.flush

#=============================================================
# Configuration
#=============================================================

# Details of the Proceedings
# Note that author names from the articles will not be reversed and they will be separated by "  and  "
# Also note that to name each bib entry, a rudimentary regex was made to escape any diacretics in the author names. 
# You may want to run through the result just in case the escape is done wrongly. 
# Note that in the code, we assume that the first article is not an article per se and has a special page count (i.e. the pages key below)
PROCEEDINGS = {
  editor: "Judita Preiss  and  David Yarowsky",
  title: "Proceedings of SENSEVAL-2 Second International Workshop on Evaluating Word Sense Disambiguation Systems",
  month: "July",
  year: "2001",
  address: "Toulouse, France",
  publisher: "Association for Computational Linguistics",
  url: "http://www.aclweb.org/anthology/S01-1",
  pages: "1--5"
}

# URL prefix for articles. These will be appended with a three digit article number. Search for sprintf to change this behavior
ARTICLE_URL_PREFIX = "http://www.aclweb.org/anthology/S01-1"
# Hard coded page numbers. These should be easy to figure out since most proceedings have articles with the same number of pages.
ARTICLE_PAGE_ONES = [ 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49, 55, 59, 63, 67, 71, 75, 79, 83, 87, 91, 95, 99, 103, 107, 111, 115, 119, 123, 127, 131, 135, 139, 143, 147, 151, 155, 159, 163 ]
# Page length per article
ARTICLE_PAGE_LENGTH = 4
# File that contains title/author pairs. Actually not a pair because they
# should be written in separate lines. i.e. first line in the file is the
# title of the first article, second line is the authors of the first 
# article. Third line is title of second article and so on.
TITLE_AUTHORS_PAIRS_FILE = "SENSEVAL01_raw_bib.txt"

ARTICLE_FILE_NAME_PREFIX = "S01-1"

BOOK_NAME = "SENSEVAL:2001"

ARTICLE_ENDFIX = "2001:SENSEVAL"

#=============================================================
# End of Configuration
#=============================================================

articles = []
lines = File.new(AUTHOR_TITLE_PAIRS_FILE).readlines
hash = {}
lines.each_with_index { |line, i|
  if i % 2 == 0
    hash[:title] = line.strip
  else
    hash[:authors] = line.gsub(/,/, " and").gsub(/\s+and\s+/, "  and  ").strip
    page = ARTICLE_PAGE_ONES[(i+1)/2-1 - 1] # - 1 because first two lines is not an article
    if i == 1
      hash[:pages] = PROCEEDINGS[:pages]
    else
      hash[:pages] = "#{page}--#{page+ARTICLE_PAGE_LENGTH-1}"
    end
    articles << hash
    hash = {}
  end
}

# Generate S01-1.bib
File.open("#{ARTICLE_FILE_NAME_PREFIX}.bib", "w") { |f|
  f.puts "@Book{#{BOOK_NAME},"
  f.puts "  editor    = {#{PROCEEDINGS[:editor]}},"
  f.puts "  title     = {#{PROCEEDINGS[:title]}},"
  f.puts "  month     = {#{PROCEEDINGS[:month]}},"
  f.puts "  year      = {#{PROCEEDINGS[:year]}},"
  f.puts "  address   = {#{PROCEEDINGS[:address]}},"
  f.puts "  publisher = {#{PROCEEDINGS[:publisher]}},"
  f.puts "  url       = {#{PROCEEDINGS[:url]}}"
  f.puts "}"
  f.puts ""

  articles.each_with_index { |a, i|
    names = a[:authors].split(/and/)
    label = nil
    if names.size == 1
      label = a[:authors].scan(/\s+([^\s]+)$/).first.first.strip.downcase
    elsif names.size == 2
      label = names.collect { |n|
        n.strip.scan(/\s+([^\s]+)$/).first.first.strip.downcase
      }.join("-")
    else
      label = names.first.strip.scan(/\s+([^\s]+)$/).first.first.strip.downcase + "-EtAl"
    end
    label = label.gsub(/\\.\{/, "").gsub(/\}/, "").gsub(/\\./, "")

    a_strings = []
    a_strings << "@InProceedings{#{label}:#{ARTICLE_ENDFIX},"
    a_strings << "  author    = {#{a[:authors]}},"
    a_strings << "  title     = {#{a[:title]}},"
    a_strings << "  booktitle = {#{PROCEEDINGS[:title]}},"
    a_strings << "  month     = {#{PROCEEDINGS[:month]}},"
    a_strings << "  year      = {#{PROCEEDINGS[:year]}},"
    a_strings << "  address   = {#{PROCEEDINGS[:address]}},"
    a_strings << "  publisher = {#{PROCEEDINGS[:publisher]}},"
    a_strings << "  pages     = {#{a[:pages]}},"
    a_strings << "  url       = {#{ARTICLE_URL_PREFIX + sprintf("%03d", i+1)}}"
    a_strings << "}"
    a_strings.each { |s| f.puts s }
    f.puts ""
    File.open("#{ARTICLE_FILE_NAME_PREFIX}#{sprintf("%03d", i+1)}.bib", "w") { |f2|
      a_strings.each { |s| f2.puts s }
    }
  }
}
