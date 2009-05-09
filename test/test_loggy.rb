require "test/unit"
require "loggy"
require "resolv"
require "yaml"


class Resolv
  def getname ip
    'www.resolved.com'
  end
end

class TestLoggy < Test::Unit::TestCase

  def setup
    @log_line = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    @cache = YAML.load_file "test/test_cache.yml"
    @loggy = Loggy.new @cache
    @log_file = 'test/test_log.log'
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
  
  def test_file_exists
    assert @loggy.open_file(@log_file)
  end
  
  def test_raise_if_file_not_found
    assert_raise StandardError do
       @loggy.open_file "not_found.txt"
    end
  end
  
  def test_file_has_contents
    actual = @loggy.get_lines(@log_file)
    assert_equal 2, actual.length
  end
  
  def test_file_raises_on_blank_log
    assert_raise StandardError do
       @loggy.get_lines "test/test_log_empty.log"
    end
  end

  def test_create_and_write_and_destory_temp_log_file
    temp = @log_file + Loggy::TEMP_EXT
    @loggy.delete_temp(@log_file) if File.exist?(temp)
    assert !File.exist?(temp)
    
    line = "hello\n"
    
    @loggy.build_temp(@log_file, line)
    assert File.exist?(temp)
    assert_equal line, IO.readlines(temp)[0]
    
    line2 = "goodbye"
    @loggy.build_temp(@log_file, line2) 
    assert_equal line2, IO.readlines(temp)[1]   
        
    @loggy.delete_temp(@log_file)
    assert !File.exist?(temp)
  end
  
  def test_raises_if_deleting_temp_file_that_doesnt_exist
    temp = @log_file + Loggy::TEMP_EXT
    # @loggy.delete_temp(@log_file)
    assert !File.exist?(temp)
    assert_raise StandardError do
      @loggy.delete_temp(@log_file)
    end
  end
  
  def test_add_threads_method_works
    log_file = "#{File.dirname(__FILE__)}/test_log.log"
    temp = log_file + Loggy::TEMP_EXT
    @loggy.delete_temp(log_file) if File.exist?(temp)
    assert !File.exist?(temp)
    @loggy.add_threads(10, log_file)
    assert File.exist?(temp)
    @loggy.delete_temp(log_file)
  end

#   def test_adds_threads
#     x = nil
#     @loggy.add_threads(5) do
#       x = 2 + 2
#     end 
#     assert_equal 4, x
#   end
  
#   def test_adds_threads
#     actual = @loggy.add_threads 5 do
#       '&block'
#     end
#     assert_equal 'block', actual
#     act = 0; 
#     @loggy.add_threads(5) do
#       act +=1 
#     end 
#     assert_equal 5, act
#   end
  
  
end
