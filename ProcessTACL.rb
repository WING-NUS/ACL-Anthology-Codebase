#!/usr/bin/env ruby
# -*- ruby -*-
# Version 130609
@@BASE_DIR = "/home/antho/"
$:.unshift("#{@@BASE_DIR}/lib/")
require 'optparse'
require 'time'
require 'rexml/document'
include REXML

# defaults
@@VERSION = [1,0]
@@INTERVAL = 100
@@PROG_NAME = File.basename($0)
@@BASE_URL = "http://www.transacl.org/papers/"
@@ACL_ANTHOLOGY_BASE = "http://www.aclweb.org/anthology/"
@@DOWNLOAD = 0
@@DEFAULT_VOLUME_INFO = "10-1"
@@FF_USER_AGENT = "\"Mozilla/6.0 (Windows NT 6.2; WOW64; rv:16.0.1) Gecko/20121011 Firefox/16.0.1\""
############################################################
# EXCEPTION HANDLING
int_handler = proc {
  # clean up code goes here
  STDERR.puts "\n# #{@@PROG_NAME} fatal\t\tReceived a 'SIGINT'\n# #{@@PROG_NAME}\t\texiting cleanly"
  exit -1
}
trap "SIGINT", int_handler

############################################################
# PUT CLASS DEFINITION HERE
class ProcessTACL
  @title = ""
  @articles = @authors_last = @authors_first = @art_pages = @href = nil

  def _read_papers (filename) 
    # parse file
    counter = -1
    author_counter = 0
    @articles = Array.new
    @authors_last = Array.new
    @authors_first = Array.new
    @art_pages = Array.new
    @art_month = Array.new
    @art_year = Array.new
    @headers = Array.new
    @href = Array.new
    current_header = nil
    
    line_num = 0
    next_line_pages = false
    next_line_href = false
    next_line_title = false
    have_title = false
    File.open(filename).each do |line|
      if (line =~ /^<dl>(.*)/i) # new article ? 
        counter = counter+1
        art_title = canon_string($1)
        if (art_title == "")
          next_line_title = true
        else 
          have_title = true
        end
      elsif (line =~ /^<dd><b><i>([^<]+)/i) # authors
        author_string = canon_string($1)
        authors = author_string.split(',')
        authors.each do |author|
          author_elements = author.split(' ')
          @authors_last[counter][author_counter] = author_elements[-1]
          @authors_first[counter][author_counter] = author_elements[0..-2].join(" ")
          author_counter = author_counter + 1
        end
        next_line_pages = true  # issue, month, year page numbering comes right after author line
      elsif next_line_pages == true # page numbers
        pages = canon_string(line)
	month = canon_string(line)
	year = canon_string(line)
        if pages =~ /\(([^\)]+)\)\:(\d+)&minus;(\d+), (\d+)/ 
          month = "#{$1}"
          pages = "#{$2}--#{$3}"
          year = "#{$4}"
        elsif pages =~ /\(([^\)]+)\)\:(\d+), (\d+)/
          month = "#{$1}"
          pages = "#{$2}"
          year = "#{$3}"
        else
          line.chop!
          STDERR.puts "# #{@@PROG_NAME} warn\t\tpages month year line looks wrong: \"#{line}\""
        end
        @art_pages[counter] = pages
        @art_year[counter] = year
        @art_month[counter] = month

        next_line_pages = false
        next_line_href = true
      elsif next_line_href == true # link at transacl.org
        line =~ /href=([^>]+)/;
        href = canon_string($1)
        @href[counter] = href
        next_line_href = false
      elsif (next_line_title == true)
        art_title = canon_string(line)
        have_title = true
        next_line_title = false
      end

      if (have_title == true) 
        art_title.chop!
        @articles[counter] = art_title
        @authors_last[counter] = Array.new
        @authors_first[counter] = Array.new
        @headers[counter] = current_header
        author_counter = 0
        have_title = false
      end
    end
    $stderr.print "# #{@@PROG_NAME} info\t\tProcessed #{counter} entries\n"
  end
  
  def canon_string (s)
    md = /^\s*(.+\S)\s*$/m.match(s)
    if (md.nil?) then return "" end
    s = md[1]
    return s
  end

  def _generate_xml(vol,num,yr)
#    doc = REXML::Document.new({:compress_whitespace => %w{title}})
    doc = REXML::Document.new
    volume = doc.add_element 'volume'
    volume.attributes["id"] = "#{vol}#{yr}"

    # BUG only for journals
    # add volume info
    frontmatter = volume.add_element 'paper'
    frontmatter.attributes["id"] = (num.to_i*1000).to_s
    title = frontmatter.add_element 'title'
    title.add_text @title

    @articles.each_with_index do |art_title,i|
      # for each article
      paper = volume.add_element 'paper'
      id = ((num.to_i*1000) + (i+1)).to_s
      paper.attributes["id"] = id
#      paper.attributes["href"] = @href[i]
      title = paper.add_element 'title'
      title.add_text "#{art_title}"
      @authors_last[i].each_with_index do |art_author_last,j|
        author = paper.add_element 'author'
        first = author.add_element 'first'
        first.add Text.new(@authors_first[i][j], false, nil, true)
        last = author.add_element 'last'
        last.add Text.new(art_author_last, false, nil, true)
      end
      pages = paper.add_element 'month'
      pages.add_text @art_month[i]
      pages = paper.add_element 'year'
      pages.add_text @art_year[i]
      href = paper.add_element 'href'
      href.add_text @href[i]
      pages = paper.add_element 'pages'
      pages.add_text @art_pages[i]
      url = paper.add_element 'url'
      anthology_url = @@ACL_ANTHOLOGY_BASE + "#{vol}#{yr}-#{id}"
      url.add_text anthology_url

      # Fetch paper if specified, otherwise just show command
      fetch_paper(@href[i],"#{vol}#{yr}-#{id.to_s}", @@DOWNLOAD)

      write_bib_file()
    end
    return doc.to_s
  end

  def _print_xml_buffer(buf)
    buf.gsub!(/(<volume[^>]+>)/) { |m| "#{m}\n\n" }
    buf.gsub!(/(<\/volume>)/) { |m| "\n#{m}\n" }
    buf.gsub!(/(<paper[^>]+>)/) { |m| "  #{m}\n" }
    buf.gsub!(/(<\/paper>)/) { |m| "  #{m}\n\n" }
    buf.gsub!(/(<(title|author|month|year|href|url|pages)>)/) { |m| "    #{m}" }
    buf.gsub!(/(<\/(title|author|month|year|href|url|pages)>)/) { |m| "#{m}\n" }
    print buf
  end
  
  def fetch_paper(href, id, fetch) 
    STDERR.puts "# #{@@PROG_NAME} info\t\tFetching #{href} as #{id}"
    buf = "wget --user-agent #{@@FF_USER_AGENT} #{href} -O #{id}.pdf"
    STDERR.puts "# #{buf}"
    if (fetch == 1)
      system buf
      sleep 10
    end
  end

  def write_bib_file
  end

  def process_papers(filename,volume,number,year)
    _read_papers(filename)
    buf = _generate_xml(volume,number,year)
    _print_xml_buffer(buf)
  end

end

############################################################

# set up options
v = @@DEFAULT_VOLUME_INFO
volume = ""
issue = ""
OptionParser.new do |opts|
  opts.banner = "usage: #{@@PROG_NAME} [options] file_name\n" +
                " e.g., #{@@PROG_NAME} -V yy-x current.html > Jyy-x.xml\n"
  opts.separator ""
  opts.on_tail("-d", "--download", "Download PDF and store as files") do @@DOWNLOAD = 1; end
  opts.on_tail("-h", "--help", "Show this message") do STDERR.puts opts; exit end
  opts.on_tail("-v", "--version", "Show version") do STDERR.puts "#{@@PROG_NAME} " + @@VERSION.join('.'); exit end
  opts.on_tail("-V", "--volume [VOLUME_STRING]", "Use provided yy-x as the volume and issue number") do |vol|
    v = vol
    v_elts = v.split(/\-/)
    volume = v_elts[0]
    issue = v_elts[1]
  end
end.parse!

pc = ProcessTACL.new()

# process each file
ARGV.each do |fn|
  $stderr.print "# #{@@PROG_NAME} info\t\tProcessing \"#{fn}\"\n"
  pc.process_papers(fn,"Q",issue,volume)
end
