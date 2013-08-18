require 'json'
require 'open-uri'

class XARF
  module Schema

    SCHEMATA_DIR = '../../../resources/'

    Schema = Struct.new(:uri, :content)

    def self.load(uri)
      schema_name = uri.split('/').last
      schema_file = File.expand_path("#{SCHEMATA_DIR}#{schema_name}", __FILE__)
      schema = File.exists?(schema_file) ? schema_file : uri

      Schema.new(uri, JSON.parse(open(schema).read))
    end
  end
end