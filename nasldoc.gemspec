# Copyright (c) 2011-2012 Jacob Hammack.
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
#     * Neither the name of the Jacob Hammack nor the names of its contributors
#     	may be used to endorse or promote products derived from this software
#     	without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JACOB HAMMACK BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

base = __FILE__
$:.unshift(File.join(File.dirname(base), 'lib'))

require 'rubygems'
require 'nasldoc'

Gem::Specification.new do |s|
	s.name							= "#{NaslDoc::APP_NAME}"
	s.version						= NaslDoc::VERSION
	s.homepage						= "http://github.com/tenable/nasldoc"
	s.summary						= "#{NaslDoc::APP_NAME}"
	s.description					= "#{NaslDoc::APP_NAME} is a NASL documentation generator"
	s.license						= "BSD"

	s.author						= "Jacob Hammack"
	s.email							= "jhammack@tenable.com"

	s.files							= Dir['[A-Z]*'] + Dir['lib/**/*'] + ["#{NaslDoc::APP_NAME}.gemspec"]
	s.bindir						= "bin"
	s.executables					= "#{NaslDoc::APP_NAME}"
	s.require_paths					= ["lib"]
	s.has_rdoc						= 'yard'
	s.extra_rdoc_files				= ["README.markdown", "NEWS.markdown", "TODO.markdown"]

	s.required_rubygems_version		= ">= 1.8.24"
	s.rubyforge_project				= "#{NaslDoc::APP_NAME}"

	s.add_dependency('nasl', ['>= 0.0.8'])
end
