#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

anthoXml2html.pl

=head1 SYNOPSYS

 RCS:$Id$

=head1 DESCRIPTION

=head1 HISTORY

 ORIGIN: created from templateApp.pl version 3.4 by Min-Yen Kan <kanmy@comp.nus.edu.sg>

 RCS:$Log$

=cut

require 5.0;
use Getopt::Std;
use strict 'vars';
# use diagnostics;

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; }		      # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "1.0";
my $defaultMode = "conference";
my $defaultSupDir = "~/public_html/supplementals/";
my $publishedSupDir = "/supplementals";
### END user customizable section

### Ctrl-C handler
sub quitHandler {
  print STDERR "\n# $progname fatal\t\tReceived a 'SIGINT'\n# $progname - exiting cleanly\n";
  exit;
}

### HELP Sub-procedure
sub Help {
  print STDERR "usage: $progname -h\t\t\t\t[invokes help]\n";
  print STDERR "       $progname -v\t\t\t\t[invokes version]\n";
  print STDERR "       $progname [-q] [-m <mode>] [-s <dir>] filename(s)...\n";
  print STDERR "Options:\n";
  print STDERR "\t-q\tQuiet Mode (don't echo license)\n";
  print STDERR "\t-m <mode>\tMode: conference, workshop, journal, default: $defaultMode\n";
  print STDERR "\t-s <supDir>\tExplicitly assign supplemental directory (default: $defaultSupDir)\n";
  print STDERR "\n";
  print STDERR "Will accept input on STDIN as a single file.\n";
  print STDERR "\n";
}

### VERSION Sub-procedure
sub Version {
  if (system ("perldoc $0")) {
    die "Need \"perldoc\" in PATH to print version information";
  }
  exit;
}

sub License {
  print STDERR "# Copyright 2005-2011 \251 by Min-Yen Kan\n";
}

###
### MAIN program
###

my $cmdLine = $0 . " " . join (" ", @ARGV);
if ($#ARGV == -1) { 		        # invoked with no arguments, possible error in execution? 
  print STDERR "# $progname info\t\tNo arguments detected, waiting for input on command line.\n";  
  print STDERR "# $progname info\t\tIf you need help, stop this program and reinvoke with \"-h\".\n";
}

$SIG{'INT'} = 'quitHandler';
getopts ('hm:qs:v');

our ($opt_q, $opt_m, $opt_s, $opt_v, $opt_h);
# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		# call License, if asked for
if ($opt_v) { Version(); exit(0); }	# call Version, if asked for
if ($opt_h) { Help(); exit (0); }	# call help, if asked for
my $supDir = (!defined $opt_s) ? $defaultSupDir : $opt_s;
my $mode = (!defined $opt_m) ? $defaultMode : $opt_m;

## standardize input stream (either STDIN on first arg on command line)
my $fh;
my $filename;
if ($filename = shift) {
 NEWFILE:
  if (!(-e $filename)) { die "# $progname crash\t\tFile \"$filename\" doesn't exist"; }
  open (*IF, $filename) || die "# $progname crash\t\tCan't open \"$filename\"";
  $fh = "IF";
} else {
  $filename = "<STDIN>";
  $fh = "STDIN";
}

my $basename = $filename;
if ($basename =~ s/\/[^\/]+$//g) { $basename .= "/"; }
else { $basename = ""; }

my @authors = ();
my $title = "";
my $volume = "";
my $paperID = "";
my $buf = "";
my $href = "";
my %toc = ();
my $videoString = ();
# Examine each line of the input XML file to process.  
# Note XML file is not really standard XML because of the need to have carriage returns
while (<$fh>) {
  if (/^\#/) { next; }		# skip comments
  elsif (/^\s+$/) { next; }	# skip blank lines
  else {
    if (/\<\?xml/) { ;
    } elsif (/<volume id=[\'\"](.+)[\'\"]>/) {		# record volume number
      $volume = $1;
      printHeader($volume,"../../index.html","../../favicon.ico", "../../images/acl-logo.gif");
    } elsif (/<paper id=[\'\"](\d+)[\'\"]( href=[\'\"]([^\"\']+)[\"\'])?>/) {
      $paperID = $1;
      $href = $3;
      @authors = ();
      $videoString = "";
#      print STDERR "$paperID - [$href]\n";
    } elsif (/<paper href=[\'\"]([^\"\']+)[\"\'] id=[\'\"](\d+)[\'\"]?>/) {
      $paperID = $2;
      $href = $1;
      @authors = ();
      $title = ();
      $videoString = "";
#      print STDERR "$paperID - [$href]\n";
    } elsif (/<address>(.+)<\/address>/i) { ; # ignore address for now
    } elsif (/<author>(.+)<\/author>/i) {
      my $authorString = $1;
      if ($authorString =~ m/<first>(.+)<\/first><last>(.+)<\/last>/i) {
	$authorString = "$1 $2";
      } elsif ($authorString =~ m/<first>(.+)<\/first><von>(.+)<\/von><last>(.+)<\/last>/i) {
	$authorString = "$1 $2 $3";
      }
      push (@authors, $authorString);
    } elsif (/<bibkey>(.+)<\/bibkey>/i) { ; # ignore bibkey for now
    } elsif (/<bibtype>(.+)<\/bibtype>/i) { ; # ignore bibtype for now
    } elsif (/<booktitle>(.+)<\/booktitle>/i) { ; # ignore bibkey for now
    } elsif (/<editor>(.+)<\/editor>/i) { ; # ignore editors for now
    } elsif (/<month>(.+)<\/month>/i) { ; # ignore months for now
    } elsif (/<\/paper>/) {				      # output
      if (($paperID % 1000 == 0 && $mode eq "conference") ||
	  ($paperID % 1000 == 0 && $mode eq "journal") ||
	  ($paperID % 100 == 0 && $mode eq "workshop")) {
        $buf .= printVolume($volume,$title,$paperID);
	$toc{"$paperID"} = $title;
      } else {
        $buf .= printPaper($volume,$title,$paperID,$href,$videoString,@authors);
      }
    } elsif (/<pages>(.*)<\/pages>/i) { ; # ignore bibkey for now
    } elsif (/<publisher>(.+)<\/publisher>/i) { ; # ignore publisher for now
    } elsif (/<title>(.+)<\/title>/i) {
      $title = $1;
    } elsif (/<url>(.+)<\/url>/i) { ; # ignore url for now
    } elsif (/<revision/i) { ;	# skip revisions, handled through file detection
    } elsif (/<\/volume>/) { ;	# skip line
    } elsif (/<year>(.+)<\/year>/i) { ; # ignore years for now
    } elsif (/<doi>(.+)<\/doi>/i) { ; # ignore for now
    } elsif (/<organization>(.+)<\/organization>/i) { ; # ignore for now
    } elsif (/<video(.+)\/>/i) { 
      my $videoData = $1;
      $videoData =~ /href=\"([^\"]+)\"/;
      my $href = $1;
      $videoData =~ /tag=\"([^\"]+)\"/;
      my $tag = $1;
      if ($videoString ne "") { $videoString .= " "; }
      $videoString .= "<A HREF=\"$href\">$tag</A>";
      if ($href !~ /^http:\/\/www.aclweb.org\//) {
	$videoString .= '<img width="10px" height="10px" src="../../images/external.gif" border="0"/>';
      }
      
    } elsif (/<issn>(.+)<\/issn>/i) { ; # ignore for now
    } elsif (/<href>(.+)<\/href>/i) { ; # ignore for now
    } elsif (/<urlalta>(.+)<\/urlalta>/i) { ; # ignore for now

    ## Min: added these last two on Mon Jun 13 20:47:31 SGT 2011
    } elsif (/<dataset>(.+)<\/dataset>/i) { ; # get dataset information through -s
    } elsif (/<software>(.+)<\/software>/i) { ; # get software information through -s
    ## Min: added this line on Fri Jul 22 00:42:45 SGT 2011
    } elsif (/<attachment>(.+)<\/attachment>/i) { ; # get software information through -s
    ## Min: added this line on Fri Jun 22 08:33:41 SGT 2012
    } elsif (/<presentation>(.+)<\/presentation>/i) { ; # get presentation information through -s
    } else {
      die "Unknown category of line! \"$_\"";
    }
  }
}
close ($fh);
if (scalar (keys %toc) != 1 ) {
  print printToC(\%toc);
}
print $buf;
printTrailer("../../index.html");

print STDERR "# $progname info\t\tMake sure to run html2xmlEntities.pl over all XML files\n";

if ($filename = shift) {
  goto NEWFILE;
}

###
### END of main program
###

# Prints the header for the HTML file
sub printHeader {
  my ($volume,$anthologyUrl,$faviconUrl,$aclLogo) = @_;
  print <<HEADER;
<html><head>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="shortcut icon" href="$faviconUrl" type="image/vnd.microsoft.icon">
<title>ACL Anthology &raquo; $volume</title><link rel="stylesheet" type="text/css" href="../../antho.css" />
HEADER
  printDivFunction();
  print <<HEADER2;
</head>

<body>
<div class="header">
<a href="$anthologyUrl"><img src="$aclLogo" width=71px height=48px border=0 align="left" alt="ACL Logo"></a>
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
    <input name="q" type="hidden" value="$volume/" />
    <input name="q" type="text" size="40" style="font-size:8pt" />
    <input type="submit" name="sa" value="Search this volume" style="font-size:8pt" />
  </form>
<!-- Google CSE Search Box Ends -->
HEADER2
#  if ($mode eq "conference") { print "<h1>$volume</h1>\n"; }
}

# Prints the division hiding javascript
sub printDivFunction {
  # from http://www.netlobo.com/div_hiding.html on Thu Dec 20 00:30:50 SGT 2007
  print <<FUNCTION;
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
FUNCTION
}

# Prints the trailer for an individual paper
sub printTrailer {
  my $anthologyUrl = shift;
print <<TRAILER;
</div>
<hr><div class="footer">
<a href="$anthologyUrl">Back to the ACL Anthology Home</a></p>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript"></script>
<script type="text/javascript">_uacct = "UA-2482907-1";urchinTracker();</script>
</div></body></html>
TRAILER
}

# Prints an individual paper entry, as a string, returns it to the caller.
sub printPaper {
  my ($volume, $title, $paperID, $href, $videoString, @authors) = @_;
  my ($prefixLetter,undef) = split(//,$volume);
  my $authorString = join ("; ", @authors);
  my $bibString = (-e "$basename$volume-$paperID.bib") ? " [<a href=\"$volume-$paperID.bib\">bib</a>]" : "";

  # process errata 
  my $errataString = "";
  my $i = 1;			# start errata count at 1
  while (-e "$basename$volume-$paperID" . "e" . $i . ".pdf") {
    $errataString .= " <A HREF=\"" . "$basename$volume-$paperID" . "e" . $i . ".pdf\">e$i</A> ";
    $i++;
  }
  if ($errataString ne "") {
    chop $errataString; 
    $errataString = " [errata: $errataString]"; 
  }
  
  # process revised versions, if any
  my $revisedVersionString = "";
  $i = 2;			# start revision count at 2
  while (-e "$basename$volume-$paperID" . "v" . $i . ".pdf") {
    $revisedVersionString .= " <A HREF=\"" . "$basename$volume-$paperID" . "v" . $i . ".pdf\">v$i</A> ";
    $i++;
  }
  if ($revisedVersionString ne "") { 
    chop $revisedVersionString; 
    $revisedVersionString = " [revisions: $revisedVersionString]"; 
  }
  if ($videoString ne "") {
    $videoString = " [" . $videoString . "]";
  }

  my $softwareString = checkSoftware($volume,$paperID);
  if ($softwareString ne "") { $softwareString = " [<a href=\"$publishedSupDir/$prefixLetter/$volume/$softwareString\">software</a>]"; } 
  my $datasetsString = checkDatasets($volume,$paperID);
  if ($datasetsString ne "") { $datasetsString = " [<a href=\"$publishedSupDir/$prefixLetter/$volume/$datasetsString\">dataset</a>]"; } 
  my $attachmentsString = checkAttachments($volume,$paperID);
  if ($attachmentsString ne "") { $attachmentsString = " [<a href=\"$publishedSupDir/$prefixLetter/$volume/$attachmentsString\">attachment</a>]"; } 
  my $presentationString = checkPresentations($volume,$paperID);
  if ($presentationString ne "") { $presentationString = " [<a href=\"$publishedSupDir/$prefixLetter/$volume/$presentationString\">presentation</a>]"; } 
  if ($href ne "") {
    return ("<p><a href=\"$href\">$volume-$paperID</a>&nbsp;<img width=\"10px\" height=\"10px\"" . 
	    " src=\"../../images/external.gif\" border=\"0\" />" .
	    $revisedVersionString . $errataString .
	    $bibString . $attachmentsString . $datasetsString . $softwareString . $presentationString . $videoString .
	    ": <b>$authorString</b><br><i>$title</i>" .
	    "\n");
  } else {
    return ("<p><a href=\"$volume-$paperID.pdf\">$volume-$paperID</a>" . 
	    $revisedVersionString . $errataString .
	    $bibString . $attachmentsString . $datasetsString . $softwareString . $presentationString  . $videoString .
	    ": <b>$authorString</b><br><i>$title</i>" .
	    "\n");
  }
}

# prints a volume, will call print paper in caller function
sub printVolume {
  my ($volume, $title, $paperID) = @_;
  my $buf = "<a name=\"$paperID\"></a><h1>$title</h1>\n";

  # entire volume edits
  my $volumeName = "$volume-$paperID";
  if ($mode eq "workshop") {
    $volumeName = substr($volumeName,0,-2);
  } elsif ($mode eq "conference" || $mode eq "journal") {
    $volumeName = substr($volumeName,0,-3);
  } else {
    die "$progname fatal\t\tUnknown mode!";
  }
#  print STDERR "$basename$volumeName.pdf";
  if (-e "$basename$volumeName.pdf") {
    $buf .= "<p><a href=\"$volumeName.pdf\">$volumeName</a>";
    if (-e "$basename$volumeName.bib") {
      $buf .= " [<a href=\"$volumeName.bib\">bib</a>]";
    }
    $buf .=": <b>Entire volume</b>";
  }

  if (-e "$basename$volume-$paperID.pdf") {
    $buf .= "<p><a href=$volume-$paperID.pdf>$volume-$paperID</a>: <i>Front Matter</i>\n";
  }
  return ($buf);
}

# Print the collapsable table of contents at the beginning of the HTML, returns it to the caller
sub printToC {
  my $toc = shift;
  my %toc = %{$toc};
  my $tocBuf = "&raquo; <a href=\"javascript:toggleLayer(\'toc\')\">Toggle Table of Contents</a> <br/><div id=\"toc\" class=\"toc\"><table>\n";
  foreach my $key (sort {$a<=>$b} (keys %toc)) {
    my $header = "";
    $tocBuf .= "<tr><th>$header</th><td><a href=\"#$key\">$toc{$key}</a></td></tr>\n"
  }
  $tocBuf .= "</table></div>\n";
  return ($tocBuf);
}

# Check for the presence of software in the supplementals directory
sub checkSoftware {
  my $volume = shift @_;
  my $id = shift @_;
  my ($prefix, undef) = split (//,$volume);

  my $software = `ls $supDir/$prefix/$volume/$volume-$id.Software* 2>/dev/null`;
  chomp $software;
  $software =~ /\/([^\/]+)$/;
  $software = $1;
  if ($software ne "") { return $software; }
}

# Check for the presence of datasets in the supplementals directory
sub checkDatasets {
  my $volume = shift @_;
  my $id = shift @_;
  my ($prefix, undef) = split (//,$volume);

  my $datasets = `ls $supDir/$prefix/$volume/$volume-$id.Datasets* 2>/dev/null`;
  chomp $datasets;
  $datasets =~ /\/([^\/]+)$/;
  $datasets = $1;
  if ($datasets ne "") { return $datasets; }
}

# Check for the presence of attachments in the supplementals directory
sub checkAttachments {
  my $volume = shift @_;
  my $id = shift @_;
  my ($prefix, undef) = split (//,$volume);

  my $attachments = `ls $supDir/$prefix/$volume/$volume-$id.Attachment* 2>/dev/null`;
#  print STDERR "ls $supDir/$prefix/$volume/$volume-$id.Attachment* 2>/dev/null";
  chomp $attachments;
  $attachments =~ /\/([^\/]+)$/;
  $attachments = $1;
  if ($attachments ne "") { return $attachments; }
}

# Check for the presence of attachments in the supplementals directory
sub checkPresentations {
  my $volume = shift @_;
  my $id = shift @_;
  my ($prefix, undef) = split (//,$volume);

  my $presentations = `ls $supDir/$prefix/$volume/$volume-$id.Presentation* 2>/dev/null`;
#  print STDERR "ls $supDir/$prefix/$volume/$volume-$id.Presentation* 2>/dev/null";
  chomp $presentations;
  $presentations =~ /\/([^\/]+)$/;
  $presentations = $1;
#  print STDERR "[ $presentations ]";
  if ($presentations ne "") { return $presentations; }
}
