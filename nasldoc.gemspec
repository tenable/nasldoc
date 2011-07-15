base = __FILE__
$:.unshift(File.join(File.dirname(base), 'lib'))

require 'rubygems'
require 'nasldoc'

Gem::Specification.new do |s|
	s.name												= "#{NaslDoc::APP_NAME}"
	s.version											= NaslDoc::VERSION
	s.homepage										= "https://researchwiki.corp.tenablesecurity.com/index.php/Nasl_doc"
	s.summary											= "#{NaslDoc::APP_NAME}"
	s.description									= "#{NaslDoc::APP_NAME} is a NASL documentation generator"
	s.license											= "BSD"

	s.author											= "Jacob Hammack"
	s.email												= "jhammack@tenable.com"

	s.files												= Dir['[A-Z]*'] + Dir['lib/**/*'] + ["#{NaslDoc::APP_NAME}.gemspec"]
	s.bindir											= "bin"
	s.executables									= "#{NaslDoc::APP_NAME}"
	s.require_paths								= ["lib"]
	s.has_rdoc										= 'yard'
	s.extra_rdoc_files						= ["README.markdown", "NEWS.markdown", "TODO.markdown"]

	s.required_rubygems_version		= ">= 1.3.6"
	s.rubyforge_project						= "#{NaslDoc::APP_NAME}"
end
