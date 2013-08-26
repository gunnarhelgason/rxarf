require 'ostruct'
require 'securerandom'
require 'erb'
require 'json'
require 'json-schema'
require 'safe_yaml'
require 'mail'

require 'rxarf/schema'
require 'rxarf/report'

class XARF

  class Header < OpenStruct
    def initialize(arg = {})
      super
    end

    def []=(key, val)
      self.send(key.to_s + '=', val)
    end

    def [](key)
      self.send(key)
    end

    def to_hash
      self.marshal_dump
    end
  end

  Attachment = Struct.new(:filename, :content)

  class Message

    attr_accessor :mail
    attr_accessor :human_readable
    attr_accessor :schema

    attr_reader :header
    attr_reader :report
    attr_reader :attachment

    SafeYAML::OPTIONS[:default_mode] = :safe

    def initialize(args, header_defaults = {}, report_defaults = {}, &block)
      @header_defaults = header_defaults
      @report_defaults = report_defaults
      @attachment = nil

      if args.is_a? Hash
        init_with_hash(args, &block)
      else
        init_with_string(args, &block)
      end
    end

    def init_with_hash(args, &block)
      @schema = args[:schema]

      if block_given?
        @header = Header.new
        @report = Report.new(@schema)
        @attachment = Attachment.new

        yield self

      else
        @header = Header.new(args[:header])
        @report = Report.new(@schema, args[:report])
        if args[:attachment]
          @attachment = Attachment.new(args[:attachment][:filename], args[:attachment][:content])
        end
        @human_readable = args[:human_readable]
      end

      assemble_report
      assemble_mail

    end

    def header=(arg)
      @header = Header.new(arg)
    end

    def report=(arg)
      @report = Report.new(@schema, arg)
    end

    def attachment=(arg)
      @attachment = Attachment.new(arg[:filename], arg[:content])
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

      @report = Report.new(@schema, report)

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

        headers = @mail.header.fields.each_with_object({}) do |k,hsh|
          hsh[k.name.downcase.gsub('-', '_')] = k.value
        end

        @header = Header.new(headers)
      end
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

      @mail.attachments[@attachment[:filename].to_s] = @attachment[:content] if @attachment
    end

    def assemble_mail_header
      @mail.header['Auto-Submitted'] = 'auto-generated'
      @mail.header['X-ARF'] = 'Yes'
      @mail.header['X-XARF'] = 'PLAIN'

      @header = set_header_defaults

      @header.marshal_dump.each_pair { |key, value| @mail.header[key] = value }
    end

    def set_header_defaults
      @header[:subject] ||= auto_subject
      Header.new(@header_defaults.merge(@header))
    end

    def auto_subject
      "abuse report about #{@report[:source]} - #{Time.now.strftime('%FT%TZ')}"
    end

    def assemble_report
      set_report_defaults
      @report = Report.new(@schema, @report_defaults.merge(@report))
    end

    def set_report_defaults
      @report_defaults.merge!({:reported_from => @header.from, :report_id => report_id})
    end

    def report_id
      (SecureRandom.hex + @header.from.partition('@')[1..2].join).force_encoding("UTF-8")
    end
  end
end