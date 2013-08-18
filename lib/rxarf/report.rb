require 'ostruct'
require 'json-schema'

class Object
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end

class XARF
  class Report < OpenStruct
    def initialize(schema, values = {})
      @schema = schema
      @properties_map = @schema.content['properties'].keys.each_with_object({}) do |prop, map|
        ruby_property = prop.downcase.gsub('-', '_')
        pm = { :property => ruby_property.to_sym, :json_name => prop }
        map[prop] = pm
        map[ruby_property] = pm
      end

      super()

      values.each_pair { |key, value| self[key] = value }

      set_defaults
    end

    def to_yaml
      self.to_h.to_yaml
    end

    def to_h
      self.each_pair.each_with_object({}) do |pair, hash|
        hash[@properties_map[pair[0].to_s][:json_name]] = pair[1]
      end
    end

    def validate
      # TODO: custom validation of date.
      
      schema = @schema.content.deep_copy
      data = self.to_h.deep_copy

      errors = JSON::Validator.fully_validate(schema, data, :version => :draft2)

      errors.reject { |error| error.include? 'ISO-8601' }
    end

    def method_missing(method, *args, &block)
      if find_method(method)
        super
      else
        raise_validation_error(method)
      end
    end

    alias_method :super_index_get, :[]
    def [](*args)
      call_super_method(:super_index_get, *args)
    end

    alias_method :super_index_assign, :[]=
    def []=(*args)
      call_super_method(:super_index_assign, *args)
    end

    private
    def set_defaults
      @schema.content['properties'].each_pair do |property, value|
        if value['enum'] && value['enum'].length == 1
            self[property] = value['enum'][0] unless self[property]
        end
      end
    end

    def find_method(method)
      m = @properties_map[method.to_s.chomp('=')]
      return nil unless m
      m[:property]
    end

    def call_super_method(super_method, *args)
      m = find_method(args[0])
      raise_validation_error(args[0]) unless m
      args[0] = m
      send(super_method, *args)
    end

    def raise_validation_error(method)
      raise(ValidationError, ("'#{method}' not a valid property in shcema #{@schema.uri}"))
    end
  end
end