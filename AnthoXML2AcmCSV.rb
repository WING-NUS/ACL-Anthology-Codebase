#!/usr/bin/env ruby
# -*- ruby -*-
# Version 081028
@@BASE_DIR = "/home/antho/"
$:.unshift("#{@@BASE_DIR}/lib/")
require 'rubygems'
require 'optparse'
require 'rexml/document'
require 'time'
include REXML

# defaults
@@VERSION = [1,0]
@@INTERVAL = 100
@@PROG_NAME = File.basename($0)

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
class AnthoXML2AcmCSV
  def initialize()
  end

  def compile_filelist(filename)
    infile = File.new(filename)
    in_doc = Document.new infile
    volume_id = in_doc.elements["volume"].attributes["id"]

    # run through paper elements
    count = 0
    filelist = Array.new
    in_doc.elements.each("*/paper/") { |e| 
      count += 1 
      if count == 1 then next end
    }
  end

  def process_file(filename)
    infile = File.new(filename)
    in_doc = Document.new infile
    volume_id = in_doc.elements["volume"].attributes["id"]
   
    # insert volume first line
    print "http://www.aclweb.org/anthology/"
    volume_url = File.basename(filename).gsub /\.xml/, ".pdf"
    print "#{volume_url}\n"
 
    # insert paper elements
    count = 0
    in_doc.elements.each("*/paper/") { |e| 
      count += 1 
      if count == 1 then next end
      row_elements = Array.new

      # handle pages
      row_elements << handle_pages(e)

      # handle first author last name
      if e.elements["author/last"]
        author_last = e.elements["author/last"].text
      else
      row_elements << "" # no authors
      end
      row_elements << author_last

      # handle electronic edition URL 
      row_elements << "http://www.aclweb.org/anthology/" + handle_ee(e, volume_id)
      print row_elements.join(",") + "\n"
   }
  end

  def handle_pages(e)
    retval = ""
    pages = e.elements["pages"]
    if pages
      if !match = /((\d+)\D+\d+)/.match(pages.text)
        retval += pages.text 
      else 
        retval += match[2]
      end
    end 
    return retval   
  end

  def handle_ee(e, volume)
    # handle electronic editions
    id = e.attributes["id"]
    return "#{volume}-#{id}"
  end

end

############################################################

# set up options
OptionParser.new do |opts|
  opts.banner = "usage: #{@@PROG_NAME} [options] file_name"

  opts.separator ""
  opts.on_tail("-h", "--help", "Show this message") do STDERR.puts opts; exit end
  opts.on_tail("-v", "--version", "Show version") do STDERR.puts "#{@@PROG_NAME} " + @@VERSION.join('.'); exit end
end.parse!

ax2ac = AnthoXML2AcmCSV.new
ax2ac.process_file(ARGV[0])
ax2ac.compile_filelist(ARGV[0])
