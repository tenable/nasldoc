module NaslDoc
  module CLI
    class CommentException < Exception
    end

    class DuplicateArgumentException < CommentException
    end

    class DuplicateTagException < CommentException
    end

    class TagFormatException < CommentException
    end

    class UnrecognizedTagException < CommentException
    end

    class UnsupportedClassException < CommentException
    end

    class Comment
      # Common attributes.
      attr_reader :name, :type, :valid

      # Freeform text attributes.
      attr_accessor :description, :summary

      # Tag attributes.
      attr_accessor :anonparams, :categories, :deprecated, :includes, :nessus
      attr_accessor :params, :remarks, :return

      # Export and function attributes.
      attr_accessor :function

      # File attributes.
      attr_accessor :filename, :signed

      # Global attributes.
      attr_accessor :variables

      @@tags = [
        'anonparam',
        'category',
        'deprecated',
        'include',
        'nessus',
        'param',
        'remark',
        'return'
      ]

      def initialize(node, path)
        # Create common attributes.
        @name = nil
        @type = nil
        @valid = false

        # Create freeform text attributes.
        @summary = nil
        @description = nil

        # Create tag attributes.
        @anonparams = {}
        @categories = []
        @deprecated = nil
        @includes = []
        @nessus = nil
        @params = {}
        @remarks = []
        @return = nil

        # Create export and function attributes.
        @function = nil

        # Create file attributes.
        @filename = nil
        @signed = nil

        # Create global attributes.
        @variables = []

        # Determine if this is a nasldoc comment.
        text = node.text.body;
        @valid = !Regexp.new("(^\s*\#{2,3}\s*$|#{trusted_regex})").match(text).nil?
        return unless @valid

        # Remember the type.
        unless node.next.nil?
          @type = node.next.class.name.gsub(/.*::/, '').downcase.to_sym
        else
          # The first comment in a file might not have a next node.
          @type = :file
        end

        # Store any other attributes we may need, since we're not keeping a
        # reference to the node.
        case @type
        when :export
          extract_function(node.function)
        when :file
          extract_file(node, path)
        when :function
          extract_function(node)
        when :global
          extract_global(node)
        else
          raise UnsupportedClassException, "The class #{node.next.class.name} is not supported."
        end

        # Parse the comment's text.
        parse(text)
      end

      def parse(text)
        # Remove the trusted header.
        re_sig = Regexp.new(trusted_regex)
        text.gsub!(re_sig, '');

        # Remove the comment prefixes ('#') from the text.
        text.gsub!(/^#+/, '');

        # Parse all the paragraphs of free-form text.
        parse_paragraphs(text)

        # Parse all the tags.
        parse_tags(text)
      end

      def parse_paragraphs(text)
        re_none = Regexp.new(/[^[:space:]]/)
        re_tags = Regexp.new(tags_regex)

        # Collect together a list of paragraphs.
        min = 9999
        paras = []
        text.each_line('') do |para|
          # Skip if the paragraph has a line starting with a tag, or has no
          # content.
          next unless para =~ re_none
          next if para =~ re_tags
          para.rstrip!
          paras << para

          # Determine the minimum indentation across all paragraphs.
          para.each_line do |line|
            padding = line[/^ */]
            min = [min, padding.length].min

            # No point in continuing if we hit the lower bound.
            break if min == 0
          end
        end

        # Strip the minimum number of spaces from the left.
        if min > 0
          regex = Regexp.new("^ {#{min}}")
          paras.map! { |p| p.gsub(regex, '') }
        end

        # The first paragraph is the summary.
        @summary = paras.shift

        # The following paragraphs are the description.
        @description = paras
      end

      def parse_tags(text)
        re_name = Regexp.new("[_a-zA-Z][_a-zA-Z0-9]*")
        re_tags = Regexp.new(tags_regex)

        # Tags start a line which continues until the next tag or blank line.
        text.each_line('') do |para|
          # Skip if the paragraph it doesn't have a line starting with a tag.
          next if para !~ re_tags

          # Break the paragraphs into blocks, each starting with a tag.
          until para.empty?
            # Find the bounds of the block.
            beg = para.index(re_tags)
            break if beg.nil?
            fin = para.index(re_tags, beg + 1) || -1

            # Pull the block out of the paragraph.
            block = para[beg..fin]
            para = para[fin..-1]

            # Remove the tag from the block.
            tag = block[re_tags]
            block = block[tag.length..-1]
            next if block.nil?

            # Squash all spaces on the block, being mindful that if the block is
            # nil the tag is useless.
            block.gsub!(/[ \n\r\t]+/, ' ')
            next if block.nil?
            block.strip!
            next if block.nil?

            # Squash the tag and trim the '@' off for accessing the object's
            # attribute.
            tag.lstrip!
            attr = tag[1..-1]

            case tag
            when '@anonparam', '@param'
              # Parse the argument name.
              name = block[re_name]
              block = block[name.length..-1].lstrip!

              if name.empty?
                raise TagFormatException, "Failed to parse the #{tag}'s name for #@name."
              end

              # Check for previous declarations of this name.
              if @anonparams.key?(name)
                raise DuplicateTagException, "The param '#{name}' was previously declared as an @anonparam for #@name."
              end

              if @params.key?(name) and not @params[name].nil?
                raise DuplicateTagException, "The param '#{name}' was previously declared as a @param for #@name."
              end

              hash = self.send(attr + 's')
              hash[name] = block
            when '@category'
              unless @categories.empty?
                raise DuplicateTagException, "The #{tag} tag appears more than once for #@name."
              end

              @categories = block.split(/,/).map &:strip
            when '@deprecated', '@nessus', '@return'
              unless self.send(attr).nil?
                raise DuplicateTagException, "The #{tag} tag appears more than once for #@name."
              end

              self.send(attr + '=', block)
            when '@include', '@remark'
              self.send(attr + 's').push(block)
            else
              raise UnrecognizedTagException, "The #{tag} tag is not recognized in #@name."
            end
          end
        end
      end

      def tags_regex
        "^\s*@(#{@@tags.join('|')})"
      end

      def trusted_regex
        "^#TRUSTED [[:xdigit:]]{1024}$"
      end

      def extract_file(node, path)
        # Remember the filename.
        @filename = File.basename(path)

        # Name this comment for use in error messages.
        @name = "file #@filename"

        # Determine whether the filename is signed, but don't validate the
        # signature.
        @signed = !Regexp.new(trusted_regex).match(node.text.body).nil?
      end

      def extract_function(node)
        # Remember the function name.
        fn = node.next
        @function = fn.name.name

        # Name this comment for use in error messages.
        @name = "function #@function"

        # Add in all named parameters, even ones that weren't annotated.
        fn.params.each { |arg| @params[arg.name] = nil }
      end

      def extract_global(node)
        # Remember all the variables.
        @variables = node.next.idents.map &:name

        # Name this comment for use in error messages.
        @name = "global variable(s) #{@variables.join(', ')}"
      end
    end
  end
end
