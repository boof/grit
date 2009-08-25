module Grit

  class Ref

    class << self
      def create(repo, ref_name, startpoint = nil, type = nil)
        type = extract_type type
        startpoint = startpoint_from_object repo, startpoint

        path = File.join repo.path, %W[ refs #{ type }s #{ ref_name } ]
        unless File.exists? path
          dir = File.dirname path
          FileUtils.mkdir_p dir unless File.exist? dir
          open(path, 'w') { |f| f << startpoint }
        end

        new ref_name, Commit.create(repo, :id => startpoint)
      end

      # Find all Refs
      #   +repo+ is the Repo
      #   +options+ is a Hash of options
      #
      # Returns Grit::Ref[] (baked)
      def find_all(repo, options = {})
        refs = []
        already = {}
        Dir.chdir(repo.path) do
          files = Dir.glob(prefix + '/**/*')
          files.each do |ref|
            next if !File.file?(ref)
            id = File.read(ref).chomp
            name = ref.sub("#{prefix}/", '')
            commit = Commit.create(repo, :id => id)
            if !already[name]
              refs << self.new(name, commit)
              already[name] = true
            end
          end

          if File.file?('packed-refs')
            File.readlines('packed-refs').each do |line|
              if m = /^(\w{40}) (.*?)$/.match(line)
                next if !Regexp.new('^' + prefix).match(m[2])
                name = m[2].sub("#{prefix}/", '')
                commit = Commit.create(repo, :id => m[1])
                if !already[name]
                  refs << self.new(name, commit)
                  already[name] = true
                end
              end
            end
          end
        end

        refs
      end

      protected
        def extract_type(type)
          type ||= name.split('::').last.downcase

          %w[ head remote tag ].include? type or
          raise ArgumentError, "expected head, remote or tags but was #{type}"

          type
        end
        def startpoint_from_object(repo, object)
          case object
          when String
            ref = repo.refs.find {|r| r.name == object }
            ref ? ref.commit.id : object
          when Grit::Ref; object.commit.id
          when Grit::Commit; object.id
          else
            repo.git.rev_parse nil, 'HEAD'
          end
        end
        def prefix
          "refs/#{name.to_s.gsub(/^.*::/, '').downcase}s"
        end

    end

    attr_reader :name
    attr_reader :commit

    # Instantiate a new Head
    #   +name+ is the name of the head
    #   +commit+ is the Commit that the head points to
    #
    # Returns Grit::Head (baked)
    def initialize(name, commit)
      @name, @commit = name, commit
      @repo = @commit.instance_variable_get :@repo
      @git = @repo.git
    end

    def checkout
      # TODO: should this change the HEAD?
      raise RuntimeError, 'bare repository' if @repo.bare
      invoke :checkout, @name
    end

    # Pretty object inspection
    def inspect
      %Q{#<#{self.class.name} "#{@name}">}
    end

    def ==(other)
      self.class === other and name == other.name
    end

    protected
    def invoke(cmd, *args)
      @git.send cmd, {}, *args
    end
  end # Ref

  # A Head is a named reference to a Commit. Every Head instance contains a
  # name and a Commit object.
  #
  #   r = Grit::Repo.new("/path/to/repo")
  #   h = r.heads.first
  #   h.name       # => "master"
  #   h.commit     # => #<Grit::Commit "1c09...">
  #   h.commit.id  # => "1c09f116cbc2cb4100fb6935bb162daa4723f455"
  class Head < Ref

    # Get the HEAD revision of the repo.
    #   +repo+ is the Repo
    #   +options+ is a Hash of options
    #
    # Returns Grit::Head (baked)
    def self.current(repo, options = {})
      head = File.read File.join(repo.path, 'HEAD')
      head.chomp!

      if match = /ref: refs\/heads\/(.*)/.match(head)
        commit = Commit.create repo,
            :id => repo.git.rev_parse(options, 'HEAD')

        new match[1], commit
      end
    end

    def in_branch(message = nil)
      old_ref = @repo.head
      checkout
      yield @repo

      if message
        @repo.commit_index message
        @repo.head.commit
      end
    ensure
      old_ref.checkout
    end

  end # Head

  class Remote < Ref; end

end # Grit
