require 'rxarf/message'

class XARF
  Error           = Class.new(StandardError)
  ValidationError = Class.new(Error)

  def initialize(defaults = Hash.new({}))
    @schemata = {}
    @header_defaults = defaults[:header_defaults]
    @report_defaults = {:user_agent => "RXARF (#{XARF::VERSION})"}.merge defaults[:report_defaults]
  end

  def create(args, &block)
    args[:schema] = load_schema args[:schema]
    XARF::Message.new(args, @header_defaults, @report_defaults, &block)
  end

  def load(mail_string)
    XARF::Message.new(mail_string) do |msg, schema_url|
      msg.schema = load_schema(schema_url)
    end
  end

  private
  def load_schema(schema_url)
    @schemata[schema_url] ||= XARF::Schema.load(schema_url)
  end
end