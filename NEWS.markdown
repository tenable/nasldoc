# News

#0.0.9 (March 2012)
- 

#0.0.8 (July 2011)
- Open sourced project on github
- Added daily_badurl.inc to the blacklist

#0.0.7 (June 8, 2011)
- Blacklisted "blacklist_dss.inc", "blacklist_rsa.inc", "blacklist_ssl_rsa1024.inc", "blacklist_ssl_rsa2048.inc", "daily_badip.inc", "known_CA.inc" plugins because they are pure binary and take forever to process <req: josh>
- Added an option for a output directory
- Added a internal page hyperlink via [function_name] <req:mak>
- Updated the wiki documents

#0.0.6 (May 4, 2011)
- Added @category for the function category, going to be used to generate a different function index like the wiki
- Added a @remark <string> tag for all other special notes <req:dwong/gtheall>
- Added [file#function] hyperlink generation
- Minor output bug fixes

#0.0.5 (April 3, 2011)
- Minor bug fixes

#0.0.4 (March 15, 2011)
- Turned it into a ruby gem to make it easier to use
- Parses out include()'s now and creates bind hyperlinks to that file
- Replaced \n with <br> in all of the comment fields to preserve newlines in the html output
- Added a ### tag for an overview block, like a file header
- Optimized some file reading code
