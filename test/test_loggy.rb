require 'test/unit'
require 'loggy'
require 'resolv'
require 'yaml'
require 'fileutils'

class Resolv
  alias :getname_org :getname
  def getname ip
   ip.gsub(".","") + ".me"
  end
end

class TestLoggy < Test::Unit::TestCase

  def setup
    @log_line     = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    @cache_obj    = YAML.load_file "test/log/test.cache"
    @log_file     = 'test/log/test.log'
    @temp         = "#{@log_file}#{Loggy::TEMP_EXT}"
    @log_dir      = File.split(@log_file)[0]
    @cache_ext    = Loggy::CACHE_FILE
    @cache_file   = "#{@log_dir}/#{@cache_ext}"
    setup_test_log
    @l            = Loggy.new 20, @log_file, @cache_obj
  end

  def setup_test_log
    File.delete(@temp) if File.exist?(@temp)
    FileUtils.cp "#{@log_dir}/backup.log", @log_file
  end  
  
  def test_threads_are_set
    expected      = 1
    actual        = Loggy.new expected, @log_file, @cache_obj
    assert_equal  expected, actual.threads
  end

  def test_threads_over_max_get_set_max
    expected      = Loggy::MAX_THREADS
    over_limit    = expected + 1000
    actual        = Loggy.new over_limit, @log_file, @cache_obj
    assert_equal  expected, actual.threads
  end
  
  def test_accepts_provided_cache_object
    l             = Loggy.new(20, @log_file, @cache_obj)
    assert_equal  2, l.cache.length
    assert_equal  'not-expired.me', l.cache['75.119.201.02']['name']
  end
  
  def test_creates_cache_if_none_provided
    File.delete(@cache_file) if File.exist?(@cache_file)
    l             = Loggy.new 50, @log_file
    new_cache     = "#{l.dir}/#{@cache_ext}"
    assert        File.exist?(new_cache)
  end

  def test_new_cache_is_blank
    File.delete(@cache_file) if File.exist?(@cache_file)
    l             = Loggy.new 50, @log_file
    assert        File.exist?(@cache_file)
    assert_raise  NoMethodError do
      l.cache.length
    end
  end
  
  def test_uses_existing_cache
    assert        File.exist?(@cache_file)
    FileUtils.cp  "#{@log_dir}/test.cache", @cache_file
    l             = Loggy.new 50, @log_file
    assert_equal  2, l.cache.length
    assert_equal  'not-expired.me', l.cache['75.119.201.02']['name']
  end
  
  def test_spilt_breaks_up_log_lines
    expected      = {:ip => '208.77.188.166', :request => ' - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'}
    assert_equal  expected, @l.split_up(@log_line)
  end
  
  def test_raises_if_line_not_split
    assert_raise StandardError do
       @l.split_up('asdf')
    end
  end
  
  def test_get_lines_populates_log_lines
    l             = Loggy.new 50, @log_file
    l.get_lines
    assert        !l.log_lines.empty?
  end

  def test_ip_resolves_and_caches_uncached_ip
    l             = Loggy.new 50, @log_file, @cache_obj
    l.get_lines
    line            = l.log_lines[0]
    split_line      = l.split_up line
    ip              = split_line[:ip]
    
    assert_nil      l.cache[ip]
    assert_equal    '208.77.188.01', ip
    actual          = l.resolve_ip split_line
    expected        = "2087718801.me - - ONE\n"
    assert_equal    expected, actual
    assert          l.cache[ip]
  end
  
  # working on moving everything so they aren't shared instances
  
  def test_resolves_ip_from_cache_and_matches_cache
    l               = Loggy.new 50, @log_file, @cache_obj
    cached_ip       = '75.119.201.02'
    before          = l.cache[cached_ip]
    l.get_lines
    split_line      = l.split_up(l.log_lines[1])
    ip              = split_line[:ip] 
    assert_equal    cached_ip, ip
    
    actual          = l.resolve_ip split_line
    after           = l.cache[ip]
    expected        = "not-expired.me - - TWO\n"
    
    assert_equal    expected, actual
    assert_equal    before, after
  end

  def test_ip_resolves_and_caches_if_expired
    l               = Loggy.new 50, @log_file, @cache_obj
    l.get_lines
    line            = l.log_lines.last
    split_line      = l.split_up line
    ip              = split_line[:ip]
    org_exp         = l.cache[ip]['expire']
    assert_equal    '74.125.67.12', ip
    assert_equal    'Fri May 08 18:27:32 -0700 2005', org_exp
    assert_equal    'expired.com', l.cache[ip]['name']
    expected        = "741256712.me - - TWELVE"
    actual          = l.resolve_ip split_line
    assert_equal    expected, actual
    assert_equal    "741256712.me", l.cache[ip]['name']
    assert_not_equal l.cache[ip]['expire'], org_exp
  end
  
  # should this be in here?
  def test_that_test_log_file_exists
    assert File.open(@log_file)
  end

  def test_lines_are_imported_from_log
    l               = Loggy.new 50, @log_file, @cache_obj
    l.get_lines
    assert_equal    12, l.log_lines.length
  end

  def test_build_temp_creates_temp_file_and_writes
    File.delete(@temp) if File.exist?(@temp)
    l               = Loggy.new 50, @log_file, @cache_obj
    line            = "hello"
    2.times {       l.build_temp(line) }
    assert          File.exist?(@temp)
    temp            = File.open(@temp).readlines
    assert_equal    temp.to_s, "#{line}\n#{line}\n"
  end

  def test_temp_file_gets_created_and_populated
    File.delete(@temp) if File.exist?(@temp)
    l               = Loggy.new 50, @log_file, @cache_obj
    l.get_lines
    l.add_threads
    assert          File.exist?(@temp)
    expected        = File.open("#{@log_dir}/expected.log").readlines
    actual          = File.open(@temp).readlines
    assert_equal    expected, actual
    File.delete(@temp) if File.exist?(@temp)
  end

  def test_cache_is_written_to_cache_file_and_matches
    File.delete(@cache_file) if File.exist?(@cache_file)
    l               = Loggy.new 50, @log_file, @cache_obj
    l.get_lines
    l.add_threads
    l.write_cache
    assert          File.exist?(@cache_file)
    actual          = YAML.load_file @cache_file
    assert_equal    actual, l.cache
  end

 def test_original_log_replaced_with_temp
    l               = Loggy.new 50, @log_file, @cache_obj
    l.get_lines
    l.add_threads
    l.write_cache
    original        = File.open(@log_file).readlines
    temp            = File.open(@temp).readlines
    l.replace_log
    new             = File.open(@log_file).readlines
    assert_not_equal temp, original
    assert_equal    temp, new
    assert_not_equal new, original
    assert          !File.exist?(@temp)
 end
  
  def test_original_is_converted_and_is_cached_and_temp_cleaned_up
    File.delete(@temp)        if File.exist?(@temp)
    File.delete(@cache_file)  if File.exist?(@cache_file)
    assert  FileUtils.compare_file("#{@log_dir}/backup.log", @log_file)
    l               = Loggy.new 50, @log_file
#   l.run
#     l.add_threads
#     l.write_cache
#     l.replace_log
#     assert File.exist?(@cache_file)
#     l.run
#     assert !File.exist?(@temp)
#     actual_cache = YAML.load_file("#{@log_dir}/.cache")
#     assert_equal 12, actual_cache.length
#     expected = File.open("#{@log_dir}/expected.log").readlines
#     actual = File.open(@log_file).readlines
#     assert_equal expected, actual    
#     assert FileUtils.compare_file(,   @log_file)    
#     assert File.exist?(@cache_file)
  end
  
end