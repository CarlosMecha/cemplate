#!/usr/bin/ruby

require 'erb'
require 'optparse'
require 'ostruct'
require 'yaml'

#
# Context object. Contains all the required information to inject into the template.
#
# (Idea based on Andrea Pavoni's post
# http://andreapavoni.com/blog/2013/4/create-recursive-openstruct-from-a-ruby-hash)
#
class Context < OpenStruct

    def initialize(hash = nil)
        super()

        if(hash)
            hash.each() do | key, value |
                set_key(key.to_sym(), (value.is_a?(Hash) ? self.class.new(value) : value))
            end
        end
    end

    def get_binding()
        return binding()
    end

    #
    # Returns the value of the path. If error is set to true, it will
    # throw an exception when the value is not found. Otherwise, the default
    # value will be returned.
    #
    # e.g. context.get('server.port', default=8080)
    # e.g. context.get('server.host', error=true)
    #
    def get(path, default: nil, error: false)
        target = self

        path.split('.').each() do | key |
            k_sym = key.to_sym()
            if(target.has_key?(k_sym))
                target = target.get_key(k_sym)
            else
                raise ArgumentError.new("Value #{path} not found.") unless !error
                return default
            end

        end

        return target
    end

    #
    # Sets a value given the path. It will override the existing value.
    #
    def set(path, value)
        target = self
        keys = path.split('.')
        puts(keys)

        while(!keys.empty?)
            key = keys.shift()
            k_sym = key.to_sym()
            puts(keys)

            if(keys.empty?)
                target.set_key(k_sym, value)
            else
                if(!target.has_key?(k_sym) or !target.get(k_sym).is_a(Context))
                    target.set_key(k_sym, self.class.new())
                end
                target = target.get_key(k_sym)
            end
        end

        return self

    end

    #
    # Returns true if the context contains the full path.
    #
    def has?(path)
        begin
            get(path, error: true)
            return true
        rescue ArgumentError => e
            return false
        end
    end

    #
    # Merges the current context with other one, modifiying it. If the other
    # context defines the same value, it will override the current value.
    #
    def merge!(other_context)
        
        other_context.each_pair() do | key, value |
            if(value == nil)
                set_key(key, nil)
            elsif(get_key(key).respond_to?(:merge) and value.respond_to?(:merge))
                set_key(key, get_key(key).merge(value))
            else
                v = value.dup() rescue value
                set_key(key, v)
            end

        end
        
        return self
    end

    #
    # Returns a new context result of merging the current context and the
    # provided one.
    #
    def merge(other_context)
        return dup().merge!(other_context)
    end

    #
    # Sets a key.
    #
    def set_key(key, value)
        self[key] = value
        new_ostruct_member(key)
    end

    #
    # Returns true if the context has the key (as symbol).
    #
    def has_key?(key)
        return to_h().has_key?(key)
    end

    #
    # Returns the value of a key. if error is set to true,
    # it will throw an exception if not found, otherwise the default
    # value.
    #
    def get_key(key, default: nil, error: false)
        if(has_key?(key))
            return self[key]
        end
        
        raise ArgumentError.new("Value #{key} not found.") unless !error
        return default
    end
end


class Opts
    
    def self.parse(args)

        options = OpenStruct.new()
        options.force = false
        options.encoding = "utf8"
        options.context = []
        options.verbose = false
        options.output = nil
        
        opt_parser = OptionParser.new() do |opts|
            opts.banner = "Usage: ruby cemplate.rb [opts] <filename>"
        
            opts.separator("")
            opts.separator("Specific options:")
        
            opts.on("-f", "--force", "Overrides the output file if it already exists. Do it with precaution.") do
                options.force = true
            end
        
            opts.on("-v", "--verbose", "Run verbosely") do
                options.verbose = true
            end

            opts.on("-sFILE", "--settings=FILE", "Settings file (could be defined more than once)") do | settings |
                options.context.push(settings)
            end

            opts.on("-oFILE", "--output=FILE", "Output file") do | output |
                options.output = output
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
        raise "The filename must have the .cemp extension" unless /.*\.cemp$/.match(options.filename)

        if(options.context.empty?())
            options.context.push('settings.yml')
        end

        return options
        
    end

end

#
# Creates a context from a YAML file.
#
def create_context_from_yaml(filename)
    parsed = begin
        YAML.load(File.open(filename))
    end

    return Context.new(parsed)
end


#
# Parses the cemplate file using the provided context.
#
def parse(filename, context, output: nil, force: false)
    erb = ERB.new(File.read(filename))
    if(!output)
        output = filename[0..-6]
    end
    
    if(File.exists?(output) and !force)
        raise "The output #{output} file already exists."
    end

    File.open(output, 'w') do | file |
        file.write(erb.result(context.get_binding()))
    end
end

if __FILE__ == $0

    options = Opts.parse(ARGV)

    context = Context.new()

    options.context.each() do | settings |
        other_context = create_context_from_yaml(settings)
        context.merge!(other_context)
    end

    parse(options.filename, context, output: options.output, force: options.force)

end

