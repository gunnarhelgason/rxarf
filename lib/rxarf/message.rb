require 'erb'
require 'json'
require 'json-schema'
require 'safe_yaml'
require 'mail'

require 'rxarf/schema'
require 'rxarf/report'

class XARF
  class Message

    attr_accessor :mail
    attr_accessor :header
    attr_accessor :human_readable
    attr_accessor :attachment
    attr_accessor :schema

    attr_reader :report

    SafeYAML::OPTIONS[:default_mode] = :safe

    def initialize(args, header_defaults = {}, report_defaults = {}, &block)
      @header_defaults = header_defaults
      @report_defaults = report_defaults

      if args.is_a? Hash
        init_with_hash(args, &block)
      else
        init_with_string(args, &block)
      end
    end

    def init_with_hash(args, &block)
      @schema = args[:schema]

      if block_given?
        yield self
      else
        @header = @header_defaults.merge(args[:header])
        self.report = @report_defaults.merge(args[:report])
        @human_readable = args[:human_readable]
      end

      assemble_mail

    end

    def init_with_string(str, &block)
      @mail = Mail.read_from_string str

      unless @mail.mime_type == 'multipart/mixed'
        raise(ValidationError, "Content-Type is '#{@mail.mime_type}', should be 'multipart/mixed'")
      end

      unless @mail.parts.length.between?(2,3)
        raise(ValidationError, 'wrong number of mime parts in mail')
      end

      unless @mail.header['X-XARF']
        raise(ValidationError, 'missing X-XARF header')
      end

      unless @mail.header['X-XARF'].to_s == 'PLAIN'
        raise(ValidationError, "X-XARF header not set to 'PLAIN'")
      end

      unless @mail.parts[0].content_type_parameters['charset'].to_s.casecmp 'utf-8'
        raise(ValidationError, 'first mime-part not utf-8')
      end

      unless @mail.parts[0].content_type.include? 'text/plain'
        raise(ValidationError, 'first mime-part not text/plain')
      end

      unless @mail.parts[1].content_type_parameters['charset'].to_s.casecmp 'utf-8'
        raise(ValidationError, 'second mime-part not utf-8')
      end

      unless @mail.parts[1].content_type.include? 'text/plain'
        raise(ValidationError, 'second mime-part not text/plain')
      end

      unless @mail.parts[1].content_type_parameters['name'] == 'report.txt'
        raise(ValidationError, "content type parameter name is not 'report.txt' for second mime-part")
      end

      @human_readable = @mail.parts[0].body.decoded
      
      begin
        report = YAML.load(@mail.parts[1].body.decoded)
      rescue => e
        raise(ValidationError, "could not parse YAML: #{e.class}: #{e.message}")
      end

      unless report['Schema-URL']
        raise(ValidationError, "'Schema-URL' not specified")
      end

      yield(self, report['Schema-URL'])

      @report = XARF::Report.new(@schema, report)

      report_errors =  @report.validate

      unless report_errors.empty?
        raise(ValidationError, "#{report_errors.join(', ')}")
      end

      if @report[:attachment]
        attachment_content_type = @report[:attachment]
        attachment = @mail.parts[2]
        
        if attachment.nil?
          raise(ValidationError, 'YAML report specifies attachment, but no attachment is provided')
        end

        unless @mail.parts[1].content_type.include? attachment_content_type
          raise(ValidationError, 'content type mismatch')
        end

        @attachment = @mail.attachments[1]

      end
    end

    def report=(hash)
      @report = XARF::Report.new(@schema, hash)
    end

    private
    def assemble_mail
      unless @human_readable
        raise(ValidationError, 'body of 2nd mime part cannot be empty')
      end

      @mail = Mail.new

      @mail.content_type = 'multipart/mixed'

      assemble_mail_header

      renderer = ERB.new(@human_readable)

      @mail.text_part = Mail::Part.new renderer.result(binding)
      report = Mail::Part.new
      report.content_type_parameters['name'] = 'report.txt'
      report.body = @report.to_yaml
      @mail.text_part = report
    end

    def assemble_mail_header
      @mail.header['Auto-Submitted'] = 'auto-generated'
      @mail.header['X-ARF'] = 'Yes'
      @mail.header['X-RARF'] = 'PLAIN'

      @header.each_pair { |key, value| @mail.header[key] = value }
    end
  end
end