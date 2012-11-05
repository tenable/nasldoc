require 'nasldoc/cli/comment'

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
				@globals = Array.new
				@includes = Array.new

				@overview = nil

				@template_dir = Pathname.new(__FILE__).realpath.to_s.gsub('cli/application.rb', 'templates')
				@asset_dir = Pathname.new(__FILE__).realpath.to_s.gsub('cli/application.rb', 'assets')
				@current_file = "(unknown)"
			end

			# For ERB Support
			#
			def get_binding
				binding
			end

			def url path
				File.basename(path).gsub('.', '_').sub(/_inc$/, '.html')
			end

			#
			#
			def build_template name, path=nil
				path ||= name

				dest = File.basename(path).gsub(".", "_").sub(/_inc$/, "") + ".html"
				puts "[**] Creating #{dest}"
				@erb = ERB.new File.new("#{@template_dir}/#{name}.erb").read, nil, "%"
				html = @erb.result(get_binding)

				File.open("#{@options[:output_directory]}/#{dest}", 'w+') do |f|
					f.puts html
				end
			end

			def build_file_page path
				puts "[*] Processing file: #{path}"
				@current_file = File.basename(path)
				contents = File.open(path, "rb") { |f| f.read }

				# Parse the input file.
				tree = Nasl::Parser.new.parse(contents, path)

				# Collect the functions.
				@functions = Hash.new()
				tree.all(:Function).map do |fn|
					@functions[fn.name.name] = fn.params.map(&:name)
				end

				@funcs_prv = @functions.select { |n, p| n =~ /^_/ }
				@funcs_pub = @functions.reject { |n, p| @funcs_prv.key? n }

				# Collect the globals.
				@globals = tree.all(:Global).map(&:idents).flatten.map(&:name).sort

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

			def build_file_pages
				@file_list.each { |f| build_file_page(f) }
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
				puts "Functions: #{@functions.size}"
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

				# Ensure the output directory exists.
				if File.directory?(@options[:output_directory]) == false
					Dir.mkdir @options[:output_directory]
				end

				# Get rid of non-NASL files.
				@file_list = remove_blacklist(@file_list)

				# Ensure we process files in a consistent order.
				@file_list.sort!

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
