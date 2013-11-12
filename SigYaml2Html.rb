#!/usr/bin/env ruby
# -*- ruby -*-
# Version 081028
@@BASE_DIR = "/home/antho/"
$:.unshift("#{@@BASE_DIR}/lib/")
require 'rubygems'
require 'optparse'
require 'rexml/document'
require 'time'
require 'yaml'
include REXML

# defaults
@@VERSION = [1,0]
@@INTERVAL = 100
@@PROG_NAME = File.basename($0)
@@SUPPLEMENTALS_DIR = "../supplementals"
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
class SigYaml2Html
  ANTHO_PATH = "#{@@BASE_DIR}/public_html/"
  EXT_IMAGE_HTML = "<img width=\"10px\" height=\"10px\" src=\"images/external.gif\" border=\"0\" />"
  FOOTER = <<FOOT
<hr><div class="footer">
<a href="index.html">Back to the ACL Anthology Home</a></p>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript"></script>
<script type="text/javascript">_uacct = "UA-2482907-1";urchinTracker();</script>
</div></body></html>
FOOT

  def process_file(filename)
    yaml = YAML::load_file(filename)

    $stderr.puts "# #{@@PROG_NAME} info\t\tWorking on \"#{filename}\"\n"    
    puts handle_header(yaml["Name"],yaml["ShortName"],yaml["URL"])

    toc_buf = "<div id=\"toc\" class=\"toc\"><table>"
    body_buf = "<div>\n"

    yaml["Meetings"].each { |h| # for each year
      counter = 0
      h.each_pair { |year,ar| # for each venue?
        body_buf += "<h3>#{year}</h3>\n<ol>"
	ar.each { |v|
          label = year.to_s + "_" + counter.to_s

          # process entry for toc_buf
          toc_buf += (counter == 0) ? "<tr><th>#{year.to_s}</th>\n" : "<tr><th></th>"

          # process entry for body_buf
          if (v.class == String) # a Anthology identifier 
            (retval,name) = handle_antho_id(v,label)
            body_buf += retval
            toc_buf += "<td><a href=\"##{label}\">#{name}</a></td>"
            $stderr.print "# Handling #{v} as #{label}\n"
         elsif (v.class == Hash) # pointer 
            body_buf += handle_pointer(v,label)
            toc_buf += "<td><a href=\"##{label}\">#{v["Name"]}</a></td>"
            $stderr.print "# Handling pointer as #{label}\n"
         else 
            puts "# {@@PROG_NAME} fatal\t\tUnknown line \"#{v}\""
            exit(1)
          end
          counter += 1
          toc_buf += "</tr>\n"
        }
        body_buf += "</ol>\n\n"
      }
    }
    body_buf += "</div>\n"
    toc_buf += "</table></div>\n<br/>\n"

    puts toc_buf
    puts body_buf
    puts FOOTER
  end
   
  def check_bib(fs_path,path,label)
    if (File.exists?("#{fs_path}/#{path}/#{label}.bib"))
      return " [<a href=\"#{path}/#{label}.bib\">bib</a>]"
    end
    return ""
  end
  
  def handle_antho_id(v,label)
    # Handles an embedded Anthology ID by reading the appropriate XML file
    # skipping to the important <paper> elements
    name = ""
    retval = ""
    letter = v.split("")[0]
    short_year = (v.split("")[1..2]).join("")
    prefix = letter.to_s + short_year
    path = "#{ANTHO_PATH}/#{letter}/#{prefix}/#{prefix}.xml"
    venue_offset = v.split("")[4..5].join("")

    # parse file
    file = File.new(path)
    STDERR.puts path
    doc = REXML::Document.new file
    saw_header = false
    doc.elements.each("*/paper") { |p| 
      p_offset = p.attributes["id"].split("")[0..1].join("")

      # skip non-relevant files
      if (File.exists?("#{ANTHO_PATH}/#{letter}/#{prefix}/#{prefix}-#{v.split("")[4].to_s}.pdf"))
        if (p.attributes["id"].split("")[0].to_s != v.split("")[4].to_s) then next end
      else
        if (p_offset != venue_offset) then next end
      end

      if !saw_header # handle the header
        name = p.elements["title"].text 
        retval += "  <li> <a name=\"#{label}\"></a><h2>#{name}</h2><p> "

        # check for full volume
        v2_offset = venue_offset
        if (File.exists?("#{ANTHO_PATH}/#{letter}/#{prefix}/#{prefix}-#{v.split("")[4].to_s}.pdf"))
          v2_offset = v.split("")[4].to_s
        end

        if (File.exists?("#{ANTHO_PATH}/#{letter}/#{prefix}/#{prefix}-#{v2_offset}.pdf"))
          retval += "<li><a href=\"#{letter}/#{prefix}/#{prefix}-#{v2_offset}.pdf\">#{prefix}-#{v2_offset}</a>"
          # check for bib
          retval += check_bib("#{ANTHO_PATH}","#{letter}/#{prefix}","#{prefix}-#{v2_offset}")
          retval += ": <b>Entire Volume</b></li>\n"
        end
  
        # check for front matter
        if (File.exists?("#{ANTHO_PATH}/#{letter}/#{prefix}/#{v}.pdf"))
          retval += "<li><a href=\"#{letter}/#{prefix}/#{v}.pdf\">#{v}</a>"
          retval += check_bib("#{ANTHO_PATH}","#{letter}/#{prefix}","#{v}")
          retval += ": <i>Front Matter</i></p>\n"
        end 

        saw_header = true
        next
      end

      # handle individual papers
      id = p.attributes["id"]
      paper_filename_base = "#{letter}/#{prefix}/#{prefix}-#{id}"
      retval += "<li><a href=\"#{paper_filename_base}"
      retval += ".pdf\">#{prefix}-#{id}</a>"

      # handle sequential attachments (revisions, errata)
      rev_ds = [["revision","v","revisions"],["erratum","e","errata"]]
      rev_ds.each { |rev_type_ds|
        rev_count = 0
        rev_parts = ""
	p.elements.each(rev_type_ds[0]) { |rev| 
  	  rev_count += 1
	  rev_filename = "#{paper_filename_base}#{rev_type_ds[1]}#{rev.attributes["id"]}"
	  rev_parts += " <a href=\"#{rev_filename}.pdf\">#{rev_type_ds[1]}#{rev.attributes["id"]}</a>"
        }
        if rev_count != 0 
	  retval +=  " [" + rev_type_ds[2] + ":" + rev_parts + "]"
        end
      }

      # check for bib
      retval += check_bib("#{ANTHO_PATH}","#{letter}/#{prefix}","#{prefix}-#{id}")

      # check for supplementals ("attachment", "dataset", "software", "presentation")
      ["attachment","dataset","software","presentation"].each { |supp_type|
	supp_count = 0
	supp_parts = ""
	p.elements.each(supp_type) { |supp|
	  supp_count += 1
  	  supp_parts += "<a href=\"#{@@SUPPLEMENTALS_DIR}/#{letter}/#{prefix}/#{supp.text}\">#{supp_type}</a>"
	}
	if supp_count != 0
	  retval += " [#{supp_parts}]"
	end
      }

      # handle videos
      p.elements.each("video") { |v|
        retval += ' [<a href="' + v.attributes['href'] + '">' + v.attributes['tag'] + '</A><img width="10px" height="10px" src="../../images/external.gif" border="0">]'
      }

      retval += ": "

      # handle authors of individual papers
      author_array = Array.new
      had_authors = false
      authors = p.elements.each("author") { |a|
        author_parts = Array.new
        had_authors = true
        if (a.text != nil)
          author_buf = "<author>" + a.text + "</author>"
        else 
          a.elements.each { |part|
            author_parts << part.text
          }  
          author_buf = "<author>" + author_parts.join(" ") + "</author>"
        end
        author_array << author_buf
      }
      if had_authors
        retval += "<b>" + author_array.join("; ") + "</b><br/>" 
      end
 
      # handle title of paper
      retval += "<i>#{p.elements["title"].text}</i></li>\n"

      # handle supplementals

    }
    return retval, name
  end

  def handle_pointer(v,label)
    retval = "  <li> <a name=\"#{label}\"></a><h2>#{v["Name"]}</h2><p> "
    if (v["URL"])
      retval += " <a href=\"#{v["URL"]}\">To Meeting Home Page</a> #{EXT_IMAGE_HTML}"
    end
    retval += "</li>\n"
    return retval 
  end

  def handle_header(n,sn,u) 
    retval = <<HEAD
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="shortcut icon" href="favicon.ico" type="image/vnd.microsoft.icon">
<title>ACL Anthology &raquo; #{sn}</title><link rel="stylesheet" type="text/css" href="antho.css" />
<script type="text/javascript">
function toggleLayer( whichLayer ) {
  var elem, vis;
  if( document.getElementById ) // this is the way the standards work
    elem = document.getElementById( whichLayer );
  else if( document.all ) // this is the way old msie versions work
      elem = document.all[whichLayer];
  else if( document.layers ) // this is the way nn4 works
    elem = document.layers[whichLayer];
  vis = elem.style;
  if(vis.display==''&&elem.offsetWidth!=undefined&&elem.offsetHeight!=undefined)   // if the style.display value is blank we try to figure it out here
    vis.display = (elem.offsetWidth!=0&&elem.offsetHeight!=0)?'block':'none';
  vis.display = (vis.display==''||vis.display=='block')?'none':'block';
}
</script>
</head>

<body>
<div class="header">
<a href="index.html"><img src="images/acl-logo.gif" width=71px height=48px border=0 align="left" alt="ACL Logo"></a>
<span class="title">ACL Anthology</span><br/>
<span class="subtitle">A Digital Archive of Research Papers in Computational Linguistics</span>
</div>
<hr>
<!-- -------------------------------------------------------------------------------- -->
<div id="content">
<!-- Google CSE Search Box Begins  -->
  <form id="searchbox_011664571474657673452:4w9swzkcxiy" action="http://www.google.com/cse">
  <img src="http://www.google.com/coop/images/google_custom_search_smnar.gif" alt="Google search the Anthology" />
    <input type="hidden" name="cx" value="011664571474657673452:4w9swzkcxiy" />
    <input type="hidden" name="cof" value="FORID:0" />
    <input name="q" type="text" size="40" style="font-size:8pt" />
    <input type="submit" name="sa" value="Search the Anthology" style="font-size:8pt" />
  </form>
<!-- Google CSE Search Box Ends -->
<h1>#{n}</h1>
HEAD
    if (u) 
      retval += "<p><a href=\"#{u}\">To #{sn} Home Page</a> #{EXT_IMAGE_HTML}<p>"
    end 
    retval += "&raquo; <a href=\"javascript:toggleLayer('toc')\">Toggle Table of Contents</a> <br/>"
    return retval
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

sy2h = SigYaml2Html.new
sy2h.process_file(ARGV[0])
