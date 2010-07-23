#!/usr/bin/env ruby
# -*- ruby -*-
require "rexml/document"
require "rexml/xpath"
require 'optparse'
require 'ostruct'
require 'time'

# defaults
@@VERSION = [1,0]
@@INTERVAL = 100
@@PROG_NAME = File.basename($0)
@@DEBUG = false
@@OPT_X = false
############################################################
# EXCEPTION HANDLING
int_handler = proc {
  # clean up code goes here
  STDERR.puts "\n# #{@@PROG_NAME} fatal\t\tReceived a 'SIGINT'\n# #{@@PROG_NAME}\t\texiting cleanly"
  exit -1
}
trap "SIGINT", int_handler

def canonicalize(str) 
  str.sub!(/\s+$/,"")
  str.sub!(/^\s+/,"")
  str
end

def process_volume(p, fullPath, volumePattern, in_volume)
  buf = ""

  # get the proceeding link
  if(md = fullPath.match(/.+\/(\w)\d\d\/([^\/]+)-(\d+)\.xml$/))
    buf += "http://www.aclweb.org/anthology/#{md[1]}/#{md[2]}/##{md[3]}#{volumePattern}\n"
  end

  pid = p.attributes["id"]
  if (in_volume == true) 
    buf += "\n"
  end

=begin
  buf += "<h2>" + canonicalize(p.elements["title"].text) + "</h2>\n"
  buf += "<ul>\n"
  buf += "<li>X:\nFront Matter.\n0-\n"
  buf += "<ee>#{prefix}#{pid}</ee>\n"
=end
  
  buf 
end

def process_paper(p, prefix, path, stem)
  # init
  startPage = ""
  pid = p.attributes["id"]
  ee = ""
  authorString = ""

  # first author's last name
  if (p.elements['author/last'] != nil)
    authorString = p.elements['author/last'].text
  else
    if (p.elements['editor/last'] != nil)
      authorString = p.elements['editor/last'].text
    end
  end

  # title
  title = canonicalize(p.elements["title"].text)
  if title.match(/[a-z0-9A-Z]$/)
    title += "."
  end

  # ee (points now to anthology, use -x to extract DOI from bib file)
  ee = prefix + pid
  bib_file = "#{path}#{stem}-#{pid}.bib"
  doi = ""

  if(p.elements['pages'] != nil) # Looks for start page in xml file
    if(p.elements['pages'].text =~ /(\d+)\D+?\d+/ || p.elements['pages'].text =~ /^\s*(\d+)\s*$/)
      startPage = "#{$1}";
    end
  end

  if((startPage <=> "") == 0)
    begin # Looks for start page in bib file
      bf = File.open(bib_file) 
      bf.each { |l|
        if (md = l.match(/^\s*doi\s*=\s*\{(.+)\}\s*/)) then doi = md[1] end
        if (md = l.match(/^\s*pages\s*=\s*\{(\d+)\D+\d+\}\s*/)) then 
          startPage = md[1]
        end
        ee = doi if @@OPT_X
      }
    bf.close
    rescue
      # Process pdf file to find start page"
      #STDERR.puts "Warning no bib file for #{pid}. 
      pdfPath = "#{path}#{stem}-#{pid}.pdf"
      output = `/home/antho/thang/extract_page_number.pl -q -in #{pdfPath}`

      if(md = output.match(/StartPage=(\d+)\s*/))
        startPage = md[1];
        STDERR.puts "Found start page of #{startPage} in #{pdfPath}\n"
      elsif(output.match(/NoPage/)) #paper has no page number
        STDERR.puts "No page number in #{pdfPath}\n"
        startPage = "#{pid}"; #use pid instead
      else
        STDERR.puts "Fail to find page number for #{pdfPath}\n"
      end
    end
  end

  if((startPage <=> "") == 0) # Final sanity check
    startPage = "1"
  end

  newAuthorString = escapeField(authorString)
  if((newAuthorString <=> authorString) != 0)
    STDERR.puts "#{authorString} -> #{newAuthorString}\n"
  end
  
  if (@@DEBUG) then puts "BIBFILE #{bib_file}" end
  buf = "#{startPage},#{authorString},#{ee}\n"
end

def escapeField(field)
  isQuote = 0 #1: indicates that the field will be surrounded by a double quote
  
  # Fields with embedded commas must be delimited with double-quote characters.
  # Fields that contains embedded line-breaks must be surounded by double-quotes
  # Fields with leading or trailing spaces must be delimited with double-quote characters.
  if(field =~ /,/ || field =~ /[\r\n]/ || field =~ /^\s+/ || field =~ /\s+$/)
    isQuote = 1
  end

  #Fields that contain double quote characters must be surounded by double-quotes, and the embedded double-quotes must each be represented by a pair of consecutive double quotes.
  if(field =~ /"/)
    isQuote = 1;
    field.gsub!(/"/, '""')
  end

  if(isQuote == 1)
    field = "\"#{field}\""
  end

  field
end

############################################################
# set up options
@@options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = "usage: #{@@PROG_NAME} [options] antho_file.xml > dblp_file.html"

  opts.separator ""
  opts.on_tail("-d", "--debug", "Turn record matching debugging on") do @@DEBUG = true end
  opts.on_tail("-h", "--help", "Show this message") do puts opts; exit end
  opts.on_tail("-v", "--version", "Show version") do puts "#{@@PROG_NAME} " + @@VERSION.join('.'); exit end
  opts.on_tail("-x", "--extract_doi", "Electronic edition to DOI instead of ACL Anthology") do @@OPT_X = true end
end.parse!

############################################################
# Main program
f = File.open(ARGV[0])
basename = ""
path = ""
if (md = ARGV[0].match(/(.+\/)([^\/]+$)/))
  basename = md[-1]
  path = md[1]
else
  basename = ARGV[0]
  path = ""
end

stem = basename.split(/\./)[0..-2].join

#Thang add: to deal with workshop xml (retrieve, say W97 from W97-01.xml)
stem = stem.split(/\-/)[0..-2].join 

volumePattern = "000";
if(ARGV[0].match(/\/W\//))
  volumePattern = "00";
end
#end Thang add

prefix = "http://www.aclweb.org/anthology/#{stem}-"

doc = REXML::Document.new f

in_volume = false
doc.elements.each("//paper") { |p|
  if (p.attributes["id"].match(/#{volumePattern}$/)) #Thang modify replace 000 by #{volumePattern}
    buf = process_volume(p, ARGV[0], volumePattern, in_volume)
  else 
    buf = process_paper(p,prefix,path,stem)
    in_volume = true
  end
  puts buf
}
