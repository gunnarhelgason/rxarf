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

      set_defaults

      values.each_pair { |key, value| self[key] = value }

    end

    def to_yaml
      self.to_h.to_yaml
    end

    def to_h
      self.marshal_dump.each_with_object({}) do |pair, hash|
        hash[@properties_map[pair[0].to_s][:json_name]] = pair[1]
      end
    end

    def to_hash
      self.marshal_dump
    end

    def validate
      schema = @schema.content.deep_copy
      data = self.to_h.deep_copy

      errors = JSON::Validator.fully_validate(schema, data, :version => :draft2)

      date_error = validate_date(data['Date'])
      errors << date_error if date_error
      
      errors.reject { |error| error.include? 'ISO-8601' }
    end

    def method_missing(method, *args, &block)
      if find_method_symbol(method)
        super
      else
        raise_validation_error(method)
      end
    end

    def [](*args)
      send(*modify_key(args))
    end

    def []=(*args)
      new_args = modify_key(args)
      new_args[0] = (new_args[0].to_s + '=').to_sym
      send(*new_args)
    end

    private
    def validate_date(date)
      rfc2822_format = '%b %e %Y %T %z'
      rfc3339_format = '%FT%TZ'

      format = rfc2822_format
      give_up = false

      begin
        Time.strptime(date, format)
      rescue ArgumentError
        format = rfc3339_format
        unless give_up
          give_up = true
          retry
        end
        "'#{date}'' is not a valid date format"
      else
        return nil
      end
    end

    def set_defaults
      @schema.content['properties'].each_pair do |property, value|
        if value['enum'] && value['enum'].length == 1
            self[property] = value['enum'][0]
        end
      end

      unless self[:date]
        self[:date] = Time.now.strftime('%FT%TZ')
      end
    end

    def find_method_symbol(method)
      m = @properties_map[method.to_s.chomp('=')]
      return nil unless m
      m[:property]
    end

    def modify_key(args)
      m = find_method_symbol(args[0])
      raise_validation_error(args[0]) unless m
      args[0] = m
      args
    end

    def raise_validation_error(method)
      raise(ValidationError, ("'#{method}' not a valid property in shcema #{@schema.uri}"))
    end
  end
end