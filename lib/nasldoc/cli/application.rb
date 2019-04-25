################################################################################
# Copyright (c) 2011-2014, Tenable Network Security
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
################################################################################

require 'nasldoc/cli/comment'

module NaslDoc
	module CLI
		class Application
			attr_accessor :error_count

			# Initializes the Application class
			#
			# - Sets the default output directory to nasldoc_output/
			# - Sets the template directory to lib/templates
			# - Sets the assets directory to lib/assets
			#
			def initialize
				@file_list = Array.new
				@function_count = 0
				@error_count = 0
				@options = Hash.new

				@options[:output_directory] = "nasldoc_output/"

				@functions = Array.new
				@globals = Array.new
				@includes = Array.new

				@overview = nil

				@fn_ns_map = {}
				@global_map = {}
				@obj_ns_map = {}
				@obj_fn_map = {}

				@namespaces = []

				@template_dir = Pathname.new(__FILE__).realpath.to_s.gsub('cli/application.rb', 'templates')
				@asset_dir = Pathname.new(__FILE__).realpath.to_s.gsub('cli/application.rb', 'assets')
				@current_file = "(unknown)"
			end

			# For ERB Support
			#
			# @return ERB Binding for access to instance variables in templates
			def get_binding
				binding
			end

			# Generates the base name for a path
			#
			# @return htmlized file name for .inc file
			def base path
				File.basename(path, '.inc')
			end

			# Generates the HTML base name for a path
			#
			# @return htmlized file name for .inc file
			def url path
				base(path).gsub('.', '_') + '.html'
			end

			# Generates namespace mappings
			def build_namespace_map(tree, namespaces, global_map, fn_map, obj_map, obj_fn_map, level=0, prefix = nil, object = nil)
				cur_namespace = prefix
				for node in tree do
					if(node.class.to_s == "Nasl::Namespace")
						ns = node.name.name
						if(level != 0)
							ns = prefix + '::' + node.name.name
						end
						namespaces << ns
						build_namespace_map(node, namespaces, global_map, fn_map, obj_map, obj_fn_map, level + 1, ns)
					elsif(node.class.to_s == "Nasl::Function")
						fn_map[node.to_s] = cur_namespace
						if(!object.nil?)
							obj_fn_map[node.to_s] = object 
						end
					elsif(node.class.to_s == "Nasl::Object")
						obj_map[node.to_s] = cur_namespace
						build_namespace_map(node, namespaces, global_map, fn_map, obj_map, obj_fn_map, level + 1, cur_namespace, node.name.name)
					elsif(node.class.to_s == "Nasl::Global")
						global_map[node.idents[0].to_s] = cur_namespace
					end
				end
			end

			def _build_fn_name(fn)
				fn_str = ''
				ns = @fn_ns_map[fn.to_s]
				obj = @obj_fn_map[fn.to_s]
				if (!ns.nil?)
					fn_str += ns + "::"
				end
				if (!obj.nil?)
					fn_str += obj + "."
				end
				fn_str += fn.name.name
				fn_str
			end

			# Compiles a template for each file
			def build_template name, path=nil
				path ||= name

				dest = url(path)
				puts "[**] Creating #{dest}"
				@erb = ERB.new File.new("#{@template_dir}/#{name}.erb").read, nil, "%"
				html = @erb.result(get_binding)

				File.open("#{@options[:output_directory]}/#{dest}", 'w+') do |f|
					f.puts html
				end
			end

			# Processes each .inc file and sets instance variables for each template
			def build_file_page path
				puts "[*] Processing file: #{path}"
				@current_file = File.basename(path)
				contents = File.open(path, "rb") { |f| f.read }

				# Parse the input file.
				begin
					tree = Nasl::Parser.new.parse(contents, path)
				rescue Nasl::ParseException, Nasl::TokenException
					puts "[!!!] File '#{path}' couldn't be parsed. It should be added to the blacklist."
					return nil
				end

				# get namespace mapping
				build_namespace_map(tree, @namespaces, @global_map, @fn_ns_map, @obj_ns_map, @obj_fn_map)
				
				# Collect the functions.
				@functions = Hash.new()
				tree.all(:Function).map do |fn|
					ns = @fn_ns_map[fn.to_s]
					show_ns = 0
					if(fn.fn_type == "normal" and !ns.nil?)
						show_ns = 1
					end
					code_snip = fn.context(nil, false, false)

					if (!code_snip.nil?)
						tmp_code_snip = ""
						start_block = false
						block_level = 0

						for pos in 0...code_snip.length
							tmp_c = code_snip[pos].chr
							tmp_code_snip += tmp_c
							if(tmp_c == "{")
								start_block = true
								block_level += 1
							elsif(tmp_c == "}")
								block_level -= 1
							end
							if(start_block and block_level == 0)
								break
							end
						end

						code_snip = tmp_code_snip
					end

					@functions[fn.to_s] = {
						:name => fn.name.name,
						:code => code_snip,
						:params => fn.params.map(&:name),
						:namespace => ns,
						:fn_type => fn.fn_type,
						:show_ns => show_ns,
						:object => @obj_fn_map[fn.to_s],
						:name_str => _build_fn_name(fn)
					}
					@function_count += 1
				end

				@funcs_prv = {}
				@funcs_pub = {}

				for function in tree.all(:Function) do
					if (defined? function.tokens[0].type and function.tokens[0].type == :PUBLIC)
						@funcs_pub[function.to_s] = @functions[function.to_s]
					elsif (defined? function.tokens[0].type and function.tokens[0].type == :PRIVATE)
						@funcs_prv[function.to_s] = @functions[function.to_s]
					elsif (function.fn_type == 'obj' and defined? function.tokens[0].type and function.tokens[0].type.nil?)
						if(obj_fn_map[function.to_s] == function.name.name) # handle constructor
							@funcs_pub[function.to_s] = @functions[function.to_s]
						else
							@funcs_prv[function.to_s] = @functions[function.to_s]
						end
					elsif (function.name.name =~ /^_/)
						@funcs_prv[function.to_s] = @functions[function.to_s]
					else
						@funcs_pub[function.to_s] = @functions[function.to_s]
					end
				end
#				@funcs_prv = @functions.select { |n, p| n =~ /^_/ }
#				@funcs_pub = @functions.reject { |n, p| @funcs_prv.key? n }

				# Collect the globals.
				@globals = tree.all(:Global).map(&:idents).flatten.map do |id|
					if id.is_a? Nasl::Assignment
						tmp_id = id.lval.name
					else
						tmp_id = id.name
					end
					node_str = id.to_s
					ns = @global_map[node_str]
					id = tmp_id
					if (!ns.nil?)
						id = ns + "::" + id
					end
					id += "|" + node_str
				end.sort

				@globs_prv = @globals.select { |n| n =~ /^_/ }
				@globs_pub = @globals.reject { |n| @globs_prv.include? n }

				# Collect the includes.
				@includes = tree.all(:Include).map(&:filename).map(&:text).sort

				# Parse the comments.
				@comments = tree.all(:Comment)
				puts "[**] #{@comments.size} comment(s) were found"
				@comments.map! do |comm|
					begin
						NaslDoc::CLI::Comment.new(comm, path)
					rescue CommentException => e
						# A short message is okay for format errors.
						puts "[!!!] #{e.class.name} #{e.message}"
						@error_count += 1
						nil
					rescue Exception => e
						# A detailed message is given for programming errors.
						puts "[!!!] #{e.class.name} #{e.message}"
						puts e.backtrace.map{ |l| l.prepend "[!!!!] " }.join("\n")
						nil
					end
				end
				@comments.compact!
				@comments.keep_if &:valid
				puts "[**] #{@comments.size} nasldoc comment(s) were parsed"

				# Find the overview comment.
				@overview = @comments.select{ |c| c.type == :file }.shift

				build_template "file", path
			end

			# Builds each page from the file_list
			def build_file_pages
				@file_list.each do |f|
					build_file_page(f)
				end
			end

			# Copies required assets to the final build directory
			def copy_assets
				puts `cp -vr #{@asset_dir}/* #{@options[:output_directory]}/`
			end

			# Prints documentation stats to stdout
			def print_documentation_stats
				puts "\n\nDocumentation Statistics"
				puts "Files: #{@file_list.size}"
				puts "Functions: #{@function_count}"
				puts "Errors: #{@error_count}"
			end

			# Removes blacklisted files from the file list
			def remove_blacklist file_list
				blacklist = [
					"apple_device_model_list.inc",
					"blacklist_",
					"custom_CA.inc",
					"daily_badip",
					"daily_badurl.inc",
					"known_CA.inc",
					"oui.inc",
					"oval-definitions-schematron.inc",
					"plugin_feed_info.inc",
					"sc_families.inc",
					"scap_schema.inc",
					"ssl_known_cert.inc",
                                        "ssh_get_info2",
                                        "torture_cgi",
                                        "daily_badip3.inc",
                                        "cisco_ios.inc",
					"ovaldi32",
					"ovaldi64",
					"os_cves.inc",
                                        "kernel_cves.inc",
					"tenable_mw_scan32.inc",
					"tenable_mw_scan64.inc"
				]

				new_file_list = file_list.dup

				file_list.each_with_index do |file, index|
					blacklist.each do |bf|
						if file =~ /#{bf}/
							new_file_list.delete(file)
						end
					end
				end

				return new_file_list
			end

			# Parses the command line arguments
			def parse_args
				opts = OptionParser.new do |opt|
					opt.banner = "#{APP_NAME} v#{VERSION}\nTenable Network Security.\njhammack@tenable.com\n\n"
					opt.banner << "Usage: #{APP_NAME} [options] [file|directory]"

					opt.separator ''
					opt.separator 'Options'

					opt.on('-o', '--output DIRECTORY', "Directory to output results to, created if it doesn't exit") do |option|
						@options[:output_directory] = option
					end

					opt.separator ''
					opt.separator 'Other Options'

					opt.on_tail('-v', '--version', "Shows application version information") do
						puts "#{APP_NAME} - #{VERSION}"
						exit
					end

					opt.on_tail('-?', '--help', 'Show this message') do
						puts opt.to_s + "\n"
						exit
					end
				end

				if ARGV.length != 0
					opts.parse!
				else
					puts opts.to_s + "\n"
					exit
				end
			end

			# Main function for running nasldoc
			def run
				parse_args

				if File.directory?(ARGV.first) == true
					pattern = File.join(ARGV.first, '**', '*.inc')
					@file_list = Dir.glob pattern
				else
					@file_list << ARGV.first
				end

				# Ensure the output directory exists.
				if File.directory?(@options[:output_directory]) == false
					Dir.mkdir @options[:output_directory]
				end

				# Get rid of non-NASL files.
				@file_list = remove_blacklist(@file_list)

				# Ensure we process files in a consistent order.
				@file_list.sort! do |a, b|
					base(a) <=> base(b)
				end

				puts "[*] Building documentation..."

				build_template "index"
				build_file_pages
				copy_assets

				print_documentation_stats
			end
		end
	end
end
