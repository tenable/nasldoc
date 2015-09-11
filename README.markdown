#nasldoc

#Installation

Installation is really easy, all you need to do is gem install!

	% gem install nasldoc

#Usage

Using `nasldoc` is fairly simple; just pass it a directory or a single file that you want to generate the documentation for. `nasldoc` is designed to only parse .inc files which special comment markup.

	% nasldoc /opt/nessus/lib/nessus/plugins/

This will cause a directory called `nasldoc/` to be created in your current directory. This directory will contain all of the generated HTML documents. After running `nasldoc`, open `index.html` inside of `nasldoc/` and view the documentation.

#Comment Markup

`nasldoc` comments are inclosed in ## blocks and use special tags to mark items. Currently, there are only 3 tags. Tags can be added in a matter of minutes to the parser.

nasldoc supports several markup tags:

- @param - used to label named arguments to a function
- @anonparam - used to label anonymous arguments to a function
- @return - what the function returns
- @deprecated - notation for functions that shouldn't be used
- @nessus - minimum Nessus version supported
- @category - type of category for the function
- @remark - special notes or remarks

#Function Description Block

The function description block is free form text from the first ## block to the first @tag in the `nasldoc` body. The lines are split on the # and rejoined with spaces.

#Example

	## 
	# An example addition function in NASL
	#
	# @param arg1 first number to add
	# @param arg2 second number to add
	#
	# @return the sum of arg1 and arg2
	##
	function add(arg1, arg2)
	{
	  return (arg1 + arg2);
	}

#Templates

`nasldoc` uses the ERB templating engine to make generating the output HTML trivial. Attached is an example of the sidebar; ruby code can be injected to help generate the layout.

##Example

	<html>
		<head>
			<title>nasldoc</title>
			<link rel = 'stylesheet' type= 'text/css' href='stylesheet.css'>
		</head>
		<body>
			<img src='nessus.jpg' />
			<br><br><br>
			<ul>
				<% @file_list.each_with_index do |file, i| %>
					<% row_class = i % 2 == 0 ? "even" : "odd" %> 
					<% output_file = file.gsub(".", "_") %>
					<% output_file = File.basename(file).gsub(".", "_") %>
					<li class="<%= row_class %>"><a href='<%= output_file %>.html' target='content'><%= File.basename(file) %></a></li>
				<% end %>
			</ul>
			<br><br><br>
			<ul><a href='overview.html' target='content'>Home</a></ul>
		</body>
	</html>
