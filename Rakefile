$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require "nasldoc"
require 'rake'
 
task :build do
  system "gem build #{NaslDoc::APP_NAME}.gemspec"
end
 
task :release => :build do
  system "gem push nessusdb-#{NaslDoc::VERSION}.gem"
end

task :clean do
	system "rm *.gem"
	system "rm *.db"
	system "rm *.cfg"
	system "rm *.pdf"	
	system "rm -rf coverage"
end
