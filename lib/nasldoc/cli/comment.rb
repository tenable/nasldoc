module NaslDoc
  module CLI
    class DuplicateArgumentException < Exception
    end

    class DuplicateTagException < Exception
    end

    class TagFormatException < Exception
    end

    class UnrecognizedTagException < Exception
    end

    class UnsupportedClassException < Exception
    end

    class Comment
      # Common attributes.
      attr_reader :type, :valid

      # Export and function attributes.
      attr_accessor :anonparams, :categories, :deprecated, :description, :name
      attr_accessor :nessus, :params, :remarks, :return, :summary

      # Global attributes.
      attr_accessor :variables

      @@tags = [
        'anonparam',
        'category',
        'deprecated',
        'nessus',
        'param',
        'remark',
        'return'
      ]

      def initialize(node)
        # Determine if this is a nasldoc comment.
        @valid = (node.text.body =~ /^\s*##\s*$/)
        return unless @valid

        # Parse the comment's text.
        parse(node.text.body)

        # Remember the type.
        @type = node.next.class.name.gsub(/.*::/, '').downcase.to_sym

        # Store any other attributes we may need, since we're not keeping a
        # reference to the node.
        case @type
        when :export
          extract_function node.function
        when :function
          extract_function node
        when :global
          extract_global node
        else
          raise UnsupportedClassException, "The class #{node.next.class.name} is not supported."
        end
      end

      def parse(text)
        # Prune signature, which is often part of the first comment.
        text.gsub!(/^#TRUSTED \h{1024}\n/, "");

        # Remove the comment prefixes ('#') from the text.
        text.gsub!(/^#+/, '');

        # Parse all the paragraphs of free-form text.
        parse_paragraphs(text)

        # Parse all the tags.
        parse_tags(text)
      end

      def parse_paragraphs(text)
        regex = Regexp.new(tags_regex)

        # Collect together a list of paragraphs.
        min = 9999
        paras = []
        text.each_line('') do |para|
          # Skip if the paragraph has a line starting with a tag.
          next if para =~ regex
          para.rstrip!.gsub!(/^[\n\r]/, '')
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

        # Create the tag members.
        @anonparams = {}
        @categories = []
        @deprecated = nil
        @nessus = nil
        @params = {}
        @remarks = []
        @return = nil

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

            block = para[beg..fin]
            para = para[fin..-1]

            tag = block[re_tags]
            block = block[tag.length..-1].lstrip!
            tag.lstrip!
            member = tag[1..-1]

            block.gsub!(/[ \n\r\t]+/, ' ').strip!

            case tag
            when '@anonparam', '@param'
              # Parse the argument name.
              name = block[re_name]
              block = block[name.length..-1].lstrip!

              if name.empty?
                raise TagFormatException, "Failed to parse the #{tag}'s name."
              end

              # Check for previous declarations of this name.
              if @anonparams.key?(name)
                raise DuplicateTagException, "The param '#{name}' was previously declared as an '@anonparam'."
              end

              if @params.key?(name)
                raise DuplicateTagException, "The param '#{name}' was previously declared as a '@param'."
              end

              hash = self.send(member + 's')
              hash[name] = block
            when '@category'
              unless @categories.empty?
                raise DuplicateTagException, "The #{tag} tag appears more than once."
              end

              @categories = block.split(/,/).map &:strip
            when '@deprecated', '@nessus', '@return'
              unless self.send(member).nil?
                raise DuplicateTagException, "The #{tag} tag appears more than once."
              end

              self.send(member + '=', block)
            when '@remark'
              @remarks << block
            else
              raise UnrecognizedTagException, "The #{tag} tag is not recognized."
            end
          end
        end
      end

      def tags_regex
        "^\s*@(#{@@tags.join('|')})"
      end

      def extract_function(node)
      end

      def extract_global(node)
      end
    end
  end
end
