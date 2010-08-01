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
  @@ext_image_html = "<img width=\"10px\" height=\"10px\" src=\"images/external.gif\" border=\"0\" />"
  @@footer = <<FOOT
<hr><div class="footer">
<a href="index.html">Back to the ACL Anthology Home</a></p>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript"></script>
<script type="text/javascript">_uacct = "UA-2482907-1";urchinTracker();</script>
</div></body></html>
FOOT

  def process_file(filename)
    yaml = YAML::load_file(filename)
    
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
         elsif (v.class == Hash) # pointer 
            body_buf += handle_pointer(v,label)
            toc_buf += "<td><a href=\"##{label}\">#{v["Name"]}</a></td>"
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
    puts @@footer
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
      retval += "<p><a href=\"#{u}\">To #{sn} Home Page</a> #{@@ext_image_html}<p>"
    end 
    retval += "&raquo; <a href=\"javascript:toggleLayer('toc')\">Toggle Table of Contents</a> <br/>"
    return retval
  end

  def handle_antho_id(v,label)
    name = "myname"
    retval = "#{v}"
    return retval, name
  end

  def handle_pointer(v,label)
    retval = "  <li> <a name=\"#{label}\"></a><h2>#{v["Name"]}</h2><p> "
    if (v["URL"])
      retval += " <a href=\"#{v["URL"]}\">To Meeting Home Page</a> #{@@ext_image_html}"
    end
    retval += "</li>\n"
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
