require "test/unit"
require "loggy"
require "resolv"
require "yaml"


class TestLoggy < Test::Unit::TestCase

  def setup
    @log_line  = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    @cache      = YAML.load_file "test/test_cache.yml"
    @loggy      = Loggy.new @cache 
  end
  
  def Resolv.getname ip
    'www.resolved.com'
  end
  
  def test_ip_resolves_name_uncached
    actual   = @loggy.get_name '208.77.188.166'
    expected = 'www.resolved.com'
    assert_equal expected, actual
  end

  def test_ip_returns_name_from_cache
    actual   = @loggy.get_name '208.77.188.160'
    expected = 'www.from-cache.com'
    assert_equal expected, actual
  end
  
  def test_ip_resolves_name_if_expired
    actual   = @loggy.get_name '208.77.188.165'
    expected = 'www.resolved.com'
    assert_equal expected, actual
  end
  
  def test_ip_gets_cached_if_missing
    ip = '208.77.188.100'
    actual  = @loggy.get_name ip
    expected = 'www.resolved.com'
    assert_equal = expected, @cache[ip]['name']
  end
  
  def test_cached_ip_gets_updated_if_expired
    ip = '208.77.188.300'
    actual  = @loggy.get_name ip
    expected = 'www.resolved.com'
    assert_equal = expected, @cache[ip]['name']
  end

  def test_ip_gets_replaced
    actual = @loggy.replace_ip @log_line
    expected = 'www.resolved.com - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    assert_equal expected, actual
  end
  
  def test_breaks_up_log_line
    expected = {:ip => '208.77.188.166', :info => ' - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'}
    assert_equal expected, @loggy.split_line(@log_line)
  end
  
  def test_raises_if_not_split
    assert_raise StandardError do
       @loggy.split_line('asdf')
    end
  end

end
