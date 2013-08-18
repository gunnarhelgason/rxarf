require_relative './test_helper'

class TestSchema < MiniTest::Test

  def test_schema_load
    schema = XARF::Schema.load("http://www.x-arf.org/schema/abuse_login-attack_0.1.2.json")

    assert_equal 'http://www.x-arf.org/schema/abuse_login-attack_0.1.2.json', schema.uri
    assert_equal 'An abusive login-attack report', schema.content['description']
  end
end






