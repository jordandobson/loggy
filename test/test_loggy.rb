require "test/unit"
require "loggy"
require "resolv"
require "yaml"


class TestLoggy < Test::Unit::TestCase

  def setup
    @text_line  = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    @cache      = YAML.load_file "test/test_cache.yml"
    @loggy      = Loggy.new @cache 
  end
  
  def Resolv.getname ip
    'www.example.com'
  end
  
  def test_ip_returns_correct_name
    actual   = @loggy.get_name '208.77.188.166'
    expected = 'www.example.com'
    assert_equal expected, actual
  end
  
  def test_ip_gets_replaced
    actual = @loggy.replace_ip @text_line
    expected = 'www.example.com - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    assert_equal expected, actual
  end

  def test_ip_returns_name_from_cache
    actual   = @loggy.get_name '208.77.188.165'
    expected = '188-165.lax.icann.org'
    assert_equal expected, actual
  end

end