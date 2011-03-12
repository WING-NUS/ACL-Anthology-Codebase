#!/usr/bin/env ruby
# -*- ruby -*-
# Version 081028
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
@@BASE_URL = "http://www.mitpressjournals.org"
@@DOWNLOAD = 0
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
class ProcessCL
  @title = ""
  @articles = @authors_last = @authors_first = @art_metadata = @href = nil

  def _read_journal_issue (filename) 
    # parse file
    file = File.new(filename)
    counter = -1
    author_counter = 0
    @articles = Array.new
    @authors_last = Array.new
    @authors_first = Array.new
    @art_metadata = Array.new
    @headers = Array.new
    @href = Array.new
    current_header = nil
    doc = REXML::Document.new file
    doc.elements.each("//(div|span|a)") { |div|
      if div.attributes["class"] == "issueTitle"
        @title = canon_string(div.text)
      elsif div.attributes["class"] == "arttitle"
        counter = counter +1
        print "#{div.text}"
        art_title = canon_string(div.text)
        @articles[counter] = art_title
        @authors_last[counter] = Array.new
        @authors_first[counter] = Array.new
        @headers[counter] = current_header
        author_counter = 0
      # section headers
      elsif div.attributes["class"] == "subj-group"
        current_header = canon_string(div.text)
      # pages metadata
      elsif div.attributes["class"] == "art_meta"
        metadata = canon_string(div.text)
        @art_metadata[counter] = metadata
      # authors
      elsif /\/action\/doSearch\?action/.match(div.attributes["href"])
        author_elements = div.text.split(" ")
        @authors_last[counter][author_counter] = author_elements[-1]
        @authors_first[counter][author_counter] = author_elements[0..-2].join(" ")
        author_counter = author_counter + 1
      # PDF Plus link
      elsif div.attributes["class"] == "ref nowrap" and /pdfplus/.match(div.attributes["href"])
        @href[counter] = div.attributes["href"]
      end
    }
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
      title = paper.add_element 'title'
      if (@headers[i] == "Articles" || @headers[i] == "Publications Received") 
        title.add_text "#{art_title}"
      else
        title.add_text "#{@headers[i]}: #{art_title}"
      end
      @authors_last[i].each_with_index do |art_author_last,j|
        author = paper.add_element 'author'
        first = author.add_element 'first'
        first.add_text @authors_first[i][j]
        last = author.add_element 'last'
        last.add_text art_author_last
      end
      doi = paper.add_element 'doi'
      pdfplus = @href[i]
      doi_href = @href[i].gsub(/\/doi\/pdfplus\//, "")
      doi.add_text doi_href 

      if (@@DOWNLOAD == 1) 
        fetch_paper(pdfplus,"#{vol}#{yr}-#{id.to_s}")
      end

      write_bib_file()
    end
    return doc.to_s
  end

  def _print_xml_buffer(buf)
    buf.gsub!(/(<volume[^>]+>)/) { |m| "#{m}\n\n" }
    buf.gsub!(/(<\/volume>)/) { |m| "\n#{m}\n" }
    buf.gsub!(/(<paper[^>]+>)/) { |m| "  #{m}\n" }
    buf.gsub!(/(<\/paper>)/) { |m| "  #{m}\n\n" }
    buf.gsub!(/(<title>)/) { |m| "    #{m}" }
    buf.gsub!(/(<\/title>)/) { |m| "#{m}\n" }
    buf.gsub!(/(<author>)/) { |m| "    #{m}" }
    buf.gsub!(/(<\/author>)/) { |m| "#{m}\n" }
    buf.gsub!(/(<doi>)/) { |m| "    #{m}" }
    buf.gsub!(/(<\/doi>)/) { |m| "#{m}\n" }
    print buf
  end
  
  def fetch_paper(href, id) 
    url = "#{@@BASE_URL}#{href}"
    print "fetching #{url} as #{id}"
    system "wget #{url} -O #{id}.pdf"
  end

  def write_bib_file
  end

  def process_journal_issue(filename,volume,number,year)
    _read_journal_issue(filename)
    buf = _generate_xml(volume,number,year)
    _print_xml_buffer(buf)
  end

end

############################################################

# set up options
OptionParser.new do |opts|
  opts.banner = "usage: #{@@PROG_NAME} [options] file_name\n" +
                " e.g., #{@@PROG_NAME} current.html > Jyy-x.xml\n"
  opts.separator ""
  opts.on_tail("-d", "--download", "Download PDF plus and store as files") do @@DOWNLOAD = 1; end
  opts.on_tail("-h", "--help", "Show this message") do STDERR.puts opts; exit end
  opts.on_tail("-v", "--version", "Show version") do STDERR.puts "#{@@PROG_NAME} " + @@VERSION.join('.'); exit end
end.parse!

pc = ProcessCL.new()

# process each file
ARGV.each do |fn|
  $stderr.print "# #{@@PROG_NAME} info\t\tProcessing \"#{fn}\"\n"
  pc.process_journal_issue(fn,"J","3","10")
end
