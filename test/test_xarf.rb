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
      service: 'ssh'
    }

    @schema = "http://www.x-arf.org/schema/abuse_login-attack_0.1.2.json"
    @human_readable = "Human readable"
  end
  
  def test_block_create
    message = @xarf.create(schema: @schema) do |msg|
      msg.header = @header
      msg.report = @report
      msg.human_readable = @human_readable
      msg.attachment = "TODO"
    end

    assert_equal message.header[:subject], @header[:subject]
  end

  def test_hash_create
    schema = "http://www.x-arf.org/schema/abuse_login-attack_0.1.2.json"

    msg = @xarf.create(schema: schema, header: @header, report: @report, human_readable: @human_readable)
    
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
    puts msg.mail.to_s
  end
end