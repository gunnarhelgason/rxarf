require_relative './test_helper'

class TestReport < MiniTest::Test
  def setup
    @schema = XARF::Schema.load("http://www.x-arf.org/schema/abuse_login-attack_0.1.2.json")
  end

  def test_attr_access
    r = XARF::Report.new(@schema)
    r[:category] = 'abuse'
    r.source = '1.2.3.4'
    r['Report-Type'] = 'login-attack'

    assert_equal 'abuse', r.category
    assert_equal '1.2.3.4', r[:source]
    assert_equal 'login-attack', r.report_type
  end

  def test_hash_init
    hsh = {
      :category => 'abuse',
      :source => '1.2.3.4',
      'Report-Type' => "login-attack"
    }
    r = XARF::Report.new(@schema, hsh)

    assert_equal 'abuse', r[:category]
    assert_equal '1.2.3.4', r['Source']
    assert_equal 'login-attack', r.report_type
  end

  def test_defaults
    r = XARF::Report.new(@schema)

    assert_equal 'abuse', r.category
    assert_equal 'login-attack', r.report_type
    assert_equal 'text/plain', r.attachment
  end

  def test_invalid_attribute
    r = XARF::Report.new(@schema)
    
    assert_raises XARF::ValidationError do
      r.invalid
    end

    assert_raises XARF::ValidationError do
      r['invalid'] = 'invalid'
    end
  end
end