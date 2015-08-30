
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
                self[key.to_sym()] = (value.is_a?(Hash) ? self.class.new(value) : value)
                new_ostruct_member(key)
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
            if(target.to_h().has_key?(key.to_sym()))
                target = target[key.to_sym()]
            else
                if(error)
                    raise ArgumentError.new('Value #{path} not found.')
                else
                    return default
                end
            end

        end

        return target
    end

    #
    # Sets a value given the path. It will override the existing value.
    #
    def set(path, value)
        target = self
        keys = path.split(',')

        while(!keys.empty?)
            key = keys.shift()
            k_sym = key.to_sym()

            if(keys.empty?)
                target[k_sym] = value
            else
                if(!target.to_h().has_key?(k_sym) or !target[k_sym].is_a(Context))
                    target[k_sym] = Context.new()
                end
                target = target[k_sym]
            end
        end

        return self

    end

    #
    # Returns true if the context contains the full path.
    #
    def has(path)
        begin
            get(path, error=true)
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
            k_sym = key.to_sym()
            if(to_h().has_key?(k_sym) and v.is_a(Context) and self[k_sym].is_a(Context))
                self[k_sym].merge(v)
            else
                self[k_sym] = v.dup()
            end

        end
        
        return self
    end

    #
    # Returns a new context result of merging the current context and the
    # provided one.
    #
    def merge(other_context)
        new_context = self.dup()
        return new_context.merge!(other_context)
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

