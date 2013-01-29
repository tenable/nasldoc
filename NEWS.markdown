# News

#0.1.1 (January 29, 2013) 
- Fixed bug caused by target attribute in anchor tags (Mak)
- Fixed linkages, these files don't exist, they're minified (Mak)
- Add syntax highlighting (Mak)
- Add source code to function hash (Mak)
- Fixed whitespace and removed trailing whitespace (Mak)
- Fixed parsing bug caused by bad formatting of tags (Mak)
- Fixed sorting for directories. (Mak)
- Fixed minor inconsistencies. (Mak)
- Support nested directories. (Mak)

#0.1.0 (November 2012)
- Integrated the nasl gem's language parsing for acquiring comments (Mak)

#0.0.9 (March 2012)
- Fixed a show stopper

#0.0.8 (July 2011)
- Open sourced project on github
- Added daily_badurl.inc to the blacklist

#0.0.7 (June 8, 2011)
- Blacklisted "blacklist_dss.inc", "blacklist_rsa.inc", "blacklist_ssl_rsa1024.inc", "blacklist_ssl_rsa2048.inc", "daily_badip.inc", "known_CA.inc" plugins because they are pure binary and take forever to process <req: josh>
- Added an option for a output directory
- Added a internal page hyper link via [function_name] <req:mak>
- Updated the wiki documents

#0.0.6 (May 4, 2011)
- Added @category for the function category, going to be used to generate a different function index like a wiki
- Added a @remark <string> tag for all other special notes <req:dwong/gtheall>
- Added [file#function] hyper link generation
- Minor output bug fixes

#0.0.5 (April 3, 2011)
- Minor bug fixes

#0.0.4 (March 15, 2011)
- Turned it into a ruby gem to make it easier to use
- Parses out include()'s now and creates bind hyper links to that file
- Replaced \n with <br> in all of the comment fields to preserve newlines in the HTML output
- Added a ### tag for an overview block, like a file header
- Optimized some file reading code
