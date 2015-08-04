#!/usr/bin/ruby

require 'erb'
require 'optparse'
require 'ostruct'

class ConfigurationFile

    attr_reader :filename

    def initialize(filename)
        @filename = filename
    end

    # Defines if the configuration file exists.
    # _This method is not reliable since can be affected by
    # race conditions._
    def exists?()
        return File.exists?(@filename)
    end

    # Defines if the file is readable.
    # _This method is not reliable since can be affected by
    # race conditions._
    def accessible?()
        return File.file?(@filename) && File.readable?(@filename)
    end

    # Reads the content of the file and executes an optional block
    # that accepts the content as a parameter.
    def read()
        begin
            File.open(@filename) do |file|
                yield file.read() if block_given?
            end
        rescue SystemCallError
            puts('Could not read the file #{@filename}');
        end
    end

end

class Context

    def initialize()
        @prueba = "caca"
    end

    def get_binding()
        return binding()
    end

end

class Parser
    
    def initialize()
    end

    def parse(content, context)
        erb = ERB.new(content)
        puts(erb.result(context.get_binding()))
    end

end

class Opts
    
    def self.parse(args)

        options = OpenStruct.new()
        options.inplace = false
        options.encoding = "utf8"
        options.verbose = false
        
        opt_parser = OptionParser.new() do |opts|
            opts.banner = "Usage: cemplate.rb [opts] <filename>"
        
            opts.separator("")
            opts.separator("Specific options:")
        
            opts.on("-i", "--inplace", "Parses the configuration file in the same file. Do it with precaution.") do
                options.inplace = true
            end
        
            opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
                options.verbose = v
            end
        
            opts.separator("")
            opts.separator("Common options:")
        
            # No argument, shows at tail.  This will print an options summary.
            # Try it and see!
            opts.on_tail("-h", "--help", "Show this message") do
                puts(opts)
                exit
            end
        
            # Another typical switch to print the version.
            opts.on_tail("--version", "Show version") do
                puts(::Version.join('.'))
                exit
            end
        end
        
        opt_parser.parse!(args)

        options.filename = args.pop()

        raise "The filename must be specified" unless options.filename

        return options
        
    end

end

if __FILE__ == $0

    options = Opts.parse(ARGV)

    conf = ConfigurationFile.new(options.filename)
    parser = Parser.new()
    context = Context.new()

    conf.read() do |content|
        parser.parse(content, context)
    end

end

