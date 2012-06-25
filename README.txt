This repository houses the software for running the ACL Anthology
maintenance scripts.

anthoBibs2bib.pl - 
AnthoXML2AcmCSV.rb - To convert Anthology XML to ACM CSV for reporting to ACM
Portal
anthoXml2acm.rb - old script, deprecated
AnthoXML2DBLPvBib.rb - To convert Anthology XML to DBLP reporting format (for use with older files without <first>, <last> tags.  Tries to find pages in bib)
AnthoXML2DBLPvFL.rb - To convert Anthology XML to DBLP reporting format (for use with <first>, <last> tags; doesn't handle bib file for processing pages)
anthoXml2html.pl - Create Anthology HTML from XML format
html2xmlEntities.pl - Converts HTML entities to XML for Anthology XML format
ProcessCL.rb - To capture metadata and PDFPlus files from the current issue page from the Computational Linguistics journal website.
README.txt - This file
SigYaml2Html.rb - To create Anthology pages for Special Interests Groups
(SIGs) from the YAML metadata.
anthoTitleAuthorsPairs2Bibs.rb - To create bib files from a text file of title and authors strings. See file for how-to use.
