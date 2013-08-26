require_relative './test_helper'

class TestXARF < MiniTest::Test
  
  def setup
    @xarf = XARF.new

    @header = {
      to: "abuse@test.net",
      subject: "abuse complaint",
      from: 'from@isp.net'
    }

    @report = {
      category:'abuse',
      source: '1.2.3.4',
      source_type: 'ipv4',
      service: 'ssh',
      port: 22
    }

    @attachment = {
      filename: 'evidence.txt',
      content: File.read('/tmp/test.txt')
    }

    @schema = "http://www.x-arf.org/schema/abuse_login-attack_0.1.2.json"
    @human_readable = "Human readable"
  end
  
  def test_block_create
    message = @xarf.create(schema: @schema) do |msg|
      msg.header = @header
      msg.report = @report
      msg.human_readable = @human_readable
      msg.attachment = @attachment
    end

    assert_equal message.header[:subject], @header[:subject]
    puts message.mail.to_s
  end

  def test_struct_create
    message = @xarf.create(schema: @schema) do |msg|
      msg.header.to = "to@struct.net"
      msg.header.from = "from@isp.net"
      msg.header[:subject] = "subject"

      msg.report.category = 'abuse'
      msg.report.service = 'ssh'
      msg.report.source = '4.3.2.1'
      msg.report.source_type = 'ipv4'
      msg.report.port = 22
      msg.human_readable = "Human redable"
    end

    assert_equal message.header.subject, 'subject'
  end

  def test_hash_create
    msg = @xarf.create(schema: @schema, header: @header, report: @report, human_readable: @human_readable, attachment: @attachment)
    
    assert_equal msg.header[:subject], @header[:subject]
  end

  def test_load
    testdata = File.expand_path("../data/valid/ssh-report.txt", __FILE__)
    message = @xarf.load File.read testdata

    assert_includes message.human_readable, "Hello Abuse-Team"
    assert_equal "abuse", message.report['Category']
    assert_equal "ip-address", message.report.source_type
    assert_equal 'text/plain', message.attachment.mime_type
    assert_equal 'logfile.log', message.attachment.filename
  end

  def test_defaults
    header_defaults = {
      from: 'default@sender.net'
    }

    report_defaults = {
      user_agent: 'default user-agent'
    }

    x = XARF.new(header_defaults: header_defaults, report_defaults: report_defaults)
  
    msg = x.create(schema: @schema, header: @header, report: @report, human_readable: @human_readable)

    assert_equal 'default user-agent', msg.report.user_agent
  end

  def test_auto_subject
    header_without_subject = @header.reject { |k| k == :subject }
    msg = @xarf.create(schema: @schema, header: header_without_subject, report: @report, human_readable: @human_readable)

    assert_includes msg.header[:subject], "abuse report about #{@report[:source]}"
  end
end