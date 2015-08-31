
require 'yaml'
require 'ostruct'

#
# Context object. Contains all the required information to inject into the template.
#
# Developed by Andrea Pavoni
# http://andreapavoni.com/blog/2013/4/create-recursive-openstruct-from-a-ruby-hash
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

#
# Creates a context from a YAML file.
#
def create_from_yaml(filename)
    parsed = begin
        YAML.load(File.open(filename))
    end

    return Context.new(parsed)
end

