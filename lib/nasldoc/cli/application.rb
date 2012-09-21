module NaslDoc
	module CLI
		class Application

			#
			#
			def initialize
				@file_list = Array.new
				@options = Hash.new

				@options[:output_directory] = "nasldoc_ouput/"

				@functions = Array.new
				@function_count = 0

				@includes = Array.new
				@overview = Array.new
				@overview_includes = Array.new

				@template_dir = Pathname.new(__FILE__).realpath.to_s.gsub('cli/application.rb', 'templates')
				@asset_dir = Pathname.new(__FILE__).realpath.to_s.gsub('cli/application.rb', 'assets')
				@current_file = ""
			end

			# For ERB Support
			#
			def get_binding
				binding
			end

			#
			#
			def build_template name, file=nil
				if file == nil
					file = name
				end

				puts "[*] Creating #{File.basename file}.html..."
				@erb = ERB.new File.new("#{@template_dir}/#{name}.erb").read, nil, "%"
				html = @erb.result(get_binding)

				output_file = File.basename(file).gsub(".", "_")

				File.open("#{@options[:output_directory]}/#{output_file}.html", 'w+') do |f|
					f.puts html
				end
			end

			#
			#
			def build_file_pages
				@file_list.each do |file|
					puts "[*] Processing File: #{file}"
					@current_file = File.basename(file, ".inc")
					contents = File.open(file, 'rb') { |f| f.read } unless file == nil

					contents = process_file_overview contents
					process_file_includes contents
					process_file contents
					build_template "file", file
				end
			end

			#
			#
			def process_file_overview file
				regex = '###((\s*?.*?).*?)###$'

				@overview = Array.new
				@overview_includes = Array.new

				file.scan(/#{regex}/m).each do |overview_text|
					text = overview_text.first.gsub(/^#/, '')

					text.split("\n").each do |line|
						line.strip!
						if line.start_with?("@") == false and line.length != 0
							@overview << line
						else
							if line =~ /@include/
								@overview_includes << line.gsub("@include", '')
							else
								@overview << line
							end
						end
					end
				end

				@overview = @overview.join("<br />")

				return file.gsub(/#{regex}/m, '')
			end

			#
			#
			def process_file_includes file
				regex = '^include\([\'|\"](.*)[\'|\"]\);\n'

				@includes = Array.new

				file.scan(/#{regex}/).each do |include_file|
					@include = Hash.new
					@include["file"] = include_file

					@includes << @include
				end
			end

			def add_nasldoc_stubs file
				regex = '[^##((\s*?.*?).*?)##]$.(^\s*)(function)(?:\s+|(\s*&\s*))(?:|([a-zA-Z0-9_]+))\s*(\()(.*?)(\))'
				new_file = file.dup

				file.scan(/#{regex}/m).each do |b1, function, b2, name, openpar, args, closepar|
					nasldoc = ""
					line = "#{function} #{name}#{openpar}#{args}#{closepar}"

					params = args.split(",")

					nasldoc << "\n##\n"
					nasldoc << "# <Function description here>\n"
					nasldoc << "#\n"
					params.each do |arg|
						nasldoc << "# @param #{arg.strip}\n"
					end unless params.size == 0
					nasldoc << "#\n"
					nasldoc << "##\n"
					nasldoc << "#{function} #{name}#{openpar}#{args}#{closepar}"

					new_file = new_file.gsub(line, nasldoc)

				end

				puts new_file
			end

			#
			#
			def process_file file
				regex = '##((\s*?.*?).*?)##$.(^\s*)(function)(?:\s+|(\s*&\s*))(?:|([a-zA-Z0-9_]+))\s*(\()(.*?)(\))'

				@functions = Array.new

				file.scan(/#{regex}/m).each do |comments, commentz, mod, function, space, name, openpar, args, closepar|
					@function = Hash.new

					@function["name"] = name
					@function["args"] = args

					summary = ""

					comments.split("#").each do |line|
						line = line.gsub("\n", "<br />")
						line.strip!
						if line.start_with?("@") == false
							summary << " " + line
						else
							break
						end
					end

					@function["summary"] = summary.strip.gsub("\n", "<br />")

					@function["comments"] = comments = comments.gsub(/^#/, '').gsub("\n", "<br />")
					@function["nasl_doc"] = comments.gsub("@", "||@").split("||")

					anon_params = Hash.new
					params = Hash.new
					returns = Hash.new
					deprecated = Hash.new
					nessus = Hash.new
					category = Hash.new
					remark = Hash.new

					@function["nasl_doc"].each do |doc|
						if doc =~ /(\[(.*)#(.*)\])/
							file_url = $2
							function = $3
							url = file_url + "_inc.html" + "#" + function
							doc = doc.gsub($1, "<a href=\"#{url}\">#{function}</a>")
						end

						if doc =~ /(\[(.*)\])/
							function = $2
							url = @current_file + "_inc.html" + "#" + function
							doc = doc.gsub($1, "<a href=\"#{url}\">#{function}</a>")
						end

						if doc =~ /@anonparam/
							tmp = doc.sub("@anonparam", "").strip
							parm = tmp.split(' ')[0]
							anon_params[parm] = tmp.sub(parm, "")
						end

						if doc =~ /@param/
							doc.sub!("@param", "").strip!
							parm = doc.split(' ')[0]
							desc = doc.sub(parm, "")
							params[parm] = desc
						end

						if doc =~ /@return/
							doc.sub!("@return", "").strip!
							returns[doc] = doc
						end

						if doc =~ /@deprecated/
							doc.sub!("@deprecated", "").strip!
							deprecated[doc] = doc
						end

						if doc =~ /@nessus/
							doc.sub!("@nessus", "").strip!
							nessus[doc] = doc
						end

						if doc =~ /@category/
							doc.sub!("@category", "").strip!
							category[doc] = doc
						end

						if doc =~ /@remark/
							doc.sub!("@remark", "").strip!
							remark[doc] = doc
						end
					end

					@function["anon_params"] = anon_params
					@function["params"] = params
					@function["returns"] = returns
					@function["deprecated"] = deprecated
					@function["nessus"] = nessus
					@function["category"] = category
					@function["remark"] = remark

					@functions << @function
				end

				@function_count = @function_count + @functions.size
			end

			#
			#
			def copy_assets
				puts "[*] Copying stylesheet.css to output dir"
				`cp #{@asset_dir}/stylesheet.css #{@options[:output_directory]}`
				puts "[*] Copying nessus.jpg to output dir"
				`cp #{@asset_dir}/nessus.jpg #{@options[:output_directory]}`
			end

			#
			#
			def print_documentation_stats
				puts "\n\nDocumentation Statistics"
				puts "Files: #{@file_list.size}"
				puts "Functions: #{@function_count}"
			end

			#
			#
			def remove_blacklist file_list
				blacklist = [
					"blacklist_dss.inc",
					"blacklist_rsa.inc",
					"blacklist_ssl_rsa1024.inc",
					"blacklist_ssl_rsa2048.inc",
					"custom_CA.inc",
					"daily_badip.inc",
					"daily_badurl.inc",
					"known_CA.inc",
					"sc_families.inc"
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

			#
			#
			def parse_args
				opts = OptionParser.new do |opt|
					opt.banner =	"#{APP_NAME} v#{VERSION}\nJacob Hammack\njhammack@tenable.com\n\n"
					opt.banner << "Usage: #{APP_NAME} [options] [file|directory]"
					opt.separator('')
					opt.separator("Options")

					opt.on('-o','--output DIRECTORY','Directory to output results to, Created if it doesn\'t exist') do |option|
						@options[:output_directory] = option
					end

					opt.separator ''
					opt.separator 'Other Options'

					opt.on_tail('-v', '--version', "Shows application version information") do
						puts "#{APP_NAME} - #{VERSION}"
						exit
					end

					opt.on_tail("-?", "--help", "Show this message") do
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

			#
			#
			def main
				parse_args

				if File.directory?(ARGV.first) == true
					pattern = File.join(ARGV.first, "*.inc")
					@file_list = Dir.glob pattern
				else
					@file_list << ARGV.first
				end

				if File.directory?(@options[:output_directory]) == false
					Dir.mkdir @options[:output_directory]
				end

				@file_list = remove_blacklist(@file_list)

				puts "[*] Building documentation..."

				build_template "index"
				build_template "sidebar"
				build_template "overview"
				build_file_pages
				copy_assets

				print_documentation_stats
			end
		end
	end
end
