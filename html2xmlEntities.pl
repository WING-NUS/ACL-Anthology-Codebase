#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

html2xmlEntities.pl

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
my %entities = (
		"&rsquo;" => "'",

		"&agrave;" => "&#224;",
		"&aacute;" => "&#225;",
		"&Agrave;" => "&#192;",
		"á" => "&#225;",
		"&acirc;" => "&#226;",
		"&atilde;" => "&#227;",
		"&auml;" => "&#228;",
		"&aring;" => "&#229;",
		"&aelig;" => "&#230;",
		"&ccedil;" => "&#231;",
		"&egrave;" => "&#232;",
		"&eacute;" => "&#233;",
		"é" => "&#233;",
		"é" => "&#233;",
		"&ecirc;" => "&#234;",
		"&euml;" => "&#235;",
		"&igrave;" => "&#236;",
		"&iacute;" => "&#237;",
		"í" => "&#237;",
		"&icirc;" => "&#238;",
		"&iuml;" => "&#239;",
		"&eth;" => "&#240;",
		"&ntilde;" => "&#241;",
		"&nacute;" => "&#x144;",
		"&Nacute;" => "&#x143;",
		"ñ" => "&#241;",
		"&ograve;" => "&#242;",
		"&Oacute;" => "&#x00d3;",
		"&oacute;" => "&#243;",
		"ó" => "&#243;",
		"&ocirc;" => "&#244;",
		"&otilde;" => "&#245;",
		"&ouml;" => "&#246;",
		"&divide;" => "&#247;",
		"&oslash;" => "&#248;",
		"&ugrave;" => "&#249;",
		"&uacute;" => "&#250;",
		"&ucirc;" => "&#251;",
		"&uuml;" => "&#252;",
		"ü" => "&#252;",
		"&yacute;" => "&#253;",
		"&thorn;" => "&#254;",
		"&yuml;" => "&#255;",
		"&fnof;" => "&#402;",
		"&circ;" => "&#710;",
		"&tilde;" => "&#732;",

		"&rdquo;" => "&#8221;",
		"&ldquo;" => "&#8220;",
		"&rsquo;" => "&#8217;",
		"&lsquo;" => "&#8216;",

		"&abreve;" => "&#x103;",
		"&Abreve;" => "&#x102;",
		"&amacr;" =>  "&#x101;",
		"&Amacr;" =>  "&#x100;",
		"&aogon;" =>  "&#x105;",
		"&Aogon;" =>  "&#x104;",
		"&cacute;" => "&#x107;",
		"&Cacute;" => "&#x106;",
		"&ccaron;" => "&#x10D;",
		"&Ccaron;" => "&#x10C;",
		"&ccirc;" =>  "&#x109;",
		"&Ccirc;" =>  "&#x108;",
		"&cdot;" =>   "&#x10B;",
		"&Cdot;" =>   "&#x10A;",
		"&dcaron;" => "&#x10F;",
		"&Dcaron;" => "&#x10E;",
		"&dstrok;" => "&#x111;",
		"&Dstrok;" => "&#x110;",
		"&ecaron;" => "&#x11B;",
		"&Ecaron;" => "&#x11A;",
		"&Eacute;" => "&#201;",
		"&edot;" =>   "&#x117;",
		"&Edot;" =>   "&#x116;",
		"&emacr;" =>  "&#x113;",
		"&Emacr;" =>  "&#x112;",
		"&eogon;" =>  "&#x119;",
		"&Eogon;" =>  "&#x118;",
		"&gacute;" => "&#x1F5;",
		"&gbreve;" => "&#x11F;",
		"&Gbreve;" => "&#x11E;",
		"&Gcedil;" => "&#x122;",
		"&gcirc;" =>  "&#x11D;",
		"&Gcirc;" =>  "&#x11C;",
		"&gdot;" =>   "&#x121;",
		"&Gdot;" =>   "&#x120;",
		"&hcirc;" =>  "&#x125;",
		"&Hcirc;" =>  "&#x124;",
		"&hstrok;" => "&#x127;",
		"&Hstrok;" => "&#x126;",
		"&Idot;" =>   "&#x130;",
		"&Imacr;" =>  "&#x12A;",
		"&imacr;" =>  "&#x12B;",
		"&ijlig;" =>  "&#x133;",
		"&IJlig;" =>  "&#x132;",
		"&inodot;" => "&#x131;",
		"&iogon;" =>  "&#x12F;",
		"&Iogon;" =>  "&#x12E;",
		"&itilde;" => "&#x129;",
		"&Itilde;" => "&#x128;",
		"&jcirc;" =>  "&#x135;",
		"&Jcirc;" =>  "&#x134;",
		"&kcedil;" => "&#x137;",
		"&Kcedil;" => "&#x136;",
		"&kgreen;" => "&#x138;",
		"&lacute;" => "&#x13A;",
		"&Lacute;" => "&#x139;",
		"&lcaron;" => "&#x13E;",
		"&Lcaron;" => "&#x13D;",
		"&lcedil;" => "&#x13C;",
		"&Lcedil;" => "&#x13B;",
		"&lmidot;" => "&#x140;",
		"&Lmidot;" => "&#x139;",
		"&lstrok;" => "&#x142;",
		"&Lstrok;" => "&#x141;",
		"&nacute;" => "&#x144;",
		"&Nacute;" => "&#x143;",
		"&eng;" =>    "&#x14B;",
		"&ENG;" =>    "&#x14A;",
		"&napos;" =>  "&#x149;",
		"&ncaron;" => "&#x148;",
		"&Ncaron;" => "&#x147;",
		"&ncedil;" => "&#x146;",
		"&Ncedil;" => "&#x145;",
		"&odblac;" => "&#x151;",
		"&Odblac;" => "&#x150;",
		"&Omacr;" =>  "&#x14C;",
		"&omacr;" =>  "&#x14D;",
		"&oelig;" =>  "&#x153;",
		"&OElig;" =>  "&#x152;",
		"&Oslash;" => "&#216;",
		"&otilde;" => "&#245;",
		"&Otilde;" => "&#213;",
		"&racute;" => "&#x155;",
		"&Racute;" => "&#x154;",
		"&rcaron;" => "&#x159;",
		"&Rcaron;" => "&#x158;",
		"&rcedil;" => "&#x157;",
		"&Rcedil;" => "&#x156;",
		"&scirc;" =>  "&#x15C;",
		"&Scirc;" =>  "&#x15D;",
		"&tcaron;" => "&#x165;",
		"&Tcaron;" => "&#x164;",
		"&scaron;" => "&#x161;",
		"&Scaron;" => "&#x160;",
		"&tcedil;" => "&#x162;",
		"&Tcedil;" => "&#x163;",
		"&zcaron;" => "&#x1FD;",
		"&Zcaron;" => "&#381;",
		"&zdot;" =>   "&#x17C;",
		"&Zdot;" =>   "&#x17B;",

		"&quot;" => "&#34;",
		"&apos;" => "&#39;",
		"&amp;" => "&#38;",
		"&lt;" => "&#60;",
		"&gt;" => "&#62;",
		"&nbsp;" => "&#160;",
		"&iexcl;" => "&#161;",
		"&cent;" => "&#162;",
		"&pound;" => "&#163;",
		"&curren;" => "&#164;",
		"&yen;" => "&#165;",
		"&brvbar;" => "&#166;",
		"&sect;" => "&#167;",
		"&uml;" => "&#168;",
		"&copy;" => "&#169;",
		"&ordf;" => "&#170;",
		"&laquo;" => "&#171;",
		"&not;" => "&#172;",
		"&shy;" => "&#173;",
		"&reg;" => "&#174;",
		"&macr;" => "&#175;",
		"&deg;" => "&#176;",
		"&plusmn;" => "&#177;",
		"&sup2;" => "&#178;",
		"&sup3;" => "&#179;",
		"&acute;" => "&#180;",
		"&micro;" => "&#181;",
		"&para;" => "&#182;",
		"&middot;" => "&#183;",
		"&cedil;" => "&#184;",
		"&sup1;" => "&#185;",
		"&ordm;" => "&#186;",
		"&raquo;" => "&#187;",
		"&frac14;" => "&#188;",
		"&frac12;" => "&#189;",
		"&frac34;" => "&#190;",
		"&iquest;" => "&#191;",
		"&times;" => "&#215;",
		"&divide;" => "&#247;",
		"&Agrave;" => "&#192;",
		"&Aacute;" => "&#193;",
		"Á" => "&#193;",
		"&Acirc;" => "&#194;",
		"&Atilde;" => "&#195;",
		"&Auml;" => "&#196;",
		"&Aring;" => "&#197;",
		"&AElig;" => "&#198;",
		"&Ccedil;" => "&#199;",
		"&Egrave;" => "&#200;",
		"&Eacute;" => "&#201;",
		"&Ecirc;" => "&#202;",
		"&Euml;" => "&#203;",
		"&Igrave;" => "&#204;",
		"&Iacute;" => "&#205;",
		"&Icirc;" => "&#206;",
		"&Iuml;" => "&#207;",
		"&ETH;" => "&#208;",
		"&Ntilde;" => "&#209;",
		"&Ograve;" => "&#210;",
		"&Oacute;" => "&#211;",
		"&Ocirc;" => "&#212;",
		"&Otilde;" => "&#213;",
		"&Ouml;" => "&#214;",
		"&Oslash;" => "&#216;",
		"&Ugrave;" => "&#217;",
		"&Uacute;" => "&#218;",
		"&Ucirc;" => "&#219;",
		"&Uuml;" => "&#220;",
		"&Yacute;" => "&#221;",
		"&THORN;" => "&#222;",
		"&szlig;" => "&#223;",
		"&agrave;" => "&#224;",
		"&aacute;" => "&#225;",
		"&acirc;" => "&#226;",
		"&atilde;" => "&#227;",
		"&auml;" => "&#228;",
		"&aring;" => "&#229;",
		"&aelig;" => "&#230;",
		"&ccedil;" => "&#231;",
		"&egrave;" => "&#232;",
		"&eacute;" => "&#233;",
		"&ecirc;" => "&#234;",
		"&euml;" => "&#235;",
		"&igrave;" => "&#236;",
		"&iacute;" => "&#237;",
		"&icirc;" => "&#238;",
		"&iuml;" => "&#239;",
		"&eth;" => "&#240;",
		"&ntilde;" => "&#241;",
		"&ograve;" => "&#242;",
		"&oacute;" => "&#243;",
		"&ocirc;" => "&#244;",
		"&otilde;" => "&#245;",
		"&ouml;" => "&#246;",
		"&oslash;" => "&#248;",
		"&ugrave;" => "&#249;",
		"&uacute;" => "&#250;",
		"&ucirc;" => "&#251;",
		"&uuml;" => "&#252;",
		"&yacute;" => "&#253;",
		"&thorn;" => "&#254;",
		"&yuml;" => "&#255;",
	       );
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
  print STDERR "       $progname [-q] filename(s)...\n";
  print STDERR "Options:\n";
  print STDERR "\t-q\tQuiet Mode (don't echo license)\n";
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
  print STDERR "# Copyright 2005 \251 by Min-Yen Kan\n";
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
getopts ('hqv');

our ($opt_q, $opt_v, $opt_h);
# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		# call License, if asked for
if ($opt_v) { Version(); exit(0); }	# call Version, if asked for
if ($opt_h) { Help(); exit (0); }	# call help, if asked for

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

while (<$fh>) {
  foreach my $entity (keys %entities) {
    s/$entity/$entities{$entity}/g;
  }
  print
}

close ($fh);

if ($filename = shift) {
  goto NEWFILE;
}

###
### END of main program
###
