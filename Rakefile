# Copyright (c) 2011-2013 Tenable Network Security.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Tenable Network Security nor the names of its contributors
#     	may be used to endorse or promote products derived from this software
#     	without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL TENABLE NETWORK SECURITY BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require "nasldoc"
require 'rake'
require 'rake/testtask'
 
task :build do
  system "gem build #{NaslDoc::APP_NAME}.gemspec"
end

task :tag_and_bag do
	system "git tag -a #{NaslDoc::VERSION} -m 'version #{NaslDoc::VERSION}'"
	system "git push --tags"
end

task :release => [:tag_and_bag, :build] do
  system "gem push  #{NaslDoc::APP_NAME}-#{NaslDoc::VERSION}.gem"
end

task :merge do
	system "git checkout master"
	system "git merge #{NaslDoc::Version}"
	system "git push"
end

task :clean do
	system "rm *.gem"
	system "rm *.db"
	system "rm *.cfg"
	system "rm *.pdf"	
	system "rm -rf coverage"
end

Rake::TestTask.new("test") do |t|
	t.libs << "test"
	t.pattern = "test/*/*_test.rb"
	t.verbose = true
end

task :default => [:test]
