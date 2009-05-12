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
    @log_line   = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    @cache_obj  = YAML.load_file "test/log/test.cache"
    @log_file   = 'test/log/test.log'
    @temp       = "#{@log_file}#{Loggy::TEMP_EXT}"
    @log_dir    = File.split(@log_file)[0]
    @cache_ext  = Loggy::CACHE_FILE
    @cache_file = "#{@log_dir}/#{@cache_ext}"
    setup_test_log
    @l          = Loggy.new 1, @log_file, @cache_obj
  end
  
  def setup_test_log
    FileUtils.cp "#{@log_dir}/backup.log", @log_file
  end
  
  def teardown
  
  end
  
  def test_threads_are_set
    expected = 1
    actual = Loggy.new expected, @log_file, @cache_obj
    assert_equal expected, actual.threads
  end

  def test_threads_over_max_get_set_max
    expected = Loggy::MAX_THREADS
    over_limit = expected + 1000
    actual = Loggy.new over_limit, @log_file, @cache_obj
    assert_equal expected, actual.threads
  end
  
  def test_accepts_provided_cache_object
    assert_equal 2, @l.cache.length
    assert_equal 'not-expired.me', @l.cache['75.119.201.189']['name']
  end
  
  def test_creates_cache_if_none_provided
    File.delete(@cache_file) if File.exist?(@cache_file)
    l = Loggy.new 1, @log_file
    new_cache = "#{l.dir}/#{@cache_ext}"
    assert File.exist?(new_cache)
  end

  def test_new_cache_is_blank
    File.delete(@cache_file) if File.exist?(@cache_file)
    l = Loggy.new 1, @log_file
    assert File.exist?(@cache_file)
    assert_raise NoMethodError do
      l.cache.length
    end
  end
  
  def test_uses_existing_cache
    assert File.exist?(@cache_file)
    FileUtils.cp "#{@log_dir}/test.cache", @cache_file
    l = Loggy.new 1, @log_file
    assert_equal 2, @l.cache.length
    assert_equal 'not-expired.me', @l.cache['75.119.201.189']['name']
  end
  
  def test_spilt_breaks_up_log_lines
    expected = {:ip => '208.77.188.166', :request => ' - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'}
    assert_equal expected, @l.split_up(@log_line)
  end
  
  def test_raises_if_line_not_split
    assert_raise StandardError do
       @l.split_up('asdf')
    end
  end
  
  def test_get_lines_populates_log_lines
    @l.get_lines
    assert !@l.log_lines.empty?
  end

  def test_ip_resolves_and_caches_uncached_ip
    @l.get_lines
    ip = @l.log_lines[0][:ip]
    assert_nil @l.cache[ip]
    assert_equal '208.77.188.166', ip
    @l.resolve_ips
    expected = '20877188166.me'
    assert_equal expected, @l.log_lines[0][:ip]
    assert_equal expected, @l.cache[ip]['name']
  end

  def test_resolves_ip_from_cache_and_matches_cache
    @l.get_lines
    ip = @l.log_lines[1][:ip]
    assert_equal '75.119.201.189', ip
    assert @l.cache[ip]
    @l.resolve_ips
    expected = 'not-expired.me'
    assert_equal expected, @l.log_lines[1][:ip]
    assert_equal expected, @l.cache[ip]['name']
  end

  def test_ip_resolves_and_caches_if_expired
    @l.get_lines
    ip = @l.log_lines[11][:ip]
    org_exp = @l.cache[ip]['expire']
    assert_equal '74.125.67.100', ip
    assert_equal 'Fri May 08 18:27:32 -0700 2005', org_exp
    assert_equal 'expired.com', @l.cache[ip]['name']
    @l.resolve_ips
    expected = '7412567100.me'
    assert_equal expected, @l.log_lines.last[:ip]
    assert_equal expected, @l.cache[ip]['name']
    assert_not_equal @l.cache[ip]['expire'], org_exp
  end
  
  def test_file_exists
    assert @l.open_log_file(@log_file)
  end
  
  def test_raise_if_log_file_not_found
    assert_raise StandardError do
       @l.open_log_file "not_found.txt"
    end
  end
  
  def test_lines_are_imported_from_log
    @l.get_lines
    assert_equal 12, @l.log_lines.length
  end
  
  def test_file_raises_on_blank_log
    assert_raise StandardError do
       l = Loggy.new 1, "#{@log_dir}/empty.log"
       l.get_lines
    end
  end

  def test_build_temp_creates_temp_file_and_writes
    File.delete(@temp) if File.exist?(@temp)
    line = "hello"
    @l.build_temp line
    @l.build_temp line
    assert File.exist?(@temp)
    temp = File.open(@temp).readlines
    assert_equal temp.to_s, "#{line}\n#{line}\n"
  end

  def test_temp_file_gets_created_and_populated
    File.delete(@temp) if File.exist?(@temp)
    @l.get_lines
    @l.resolve_ips
    @l.write_temp
    assert File.exist?(@temp)
    assert FileUtils.compare_file("#{@log_dir}/expected.log", @temp)
  end

  def test_cache_is_written_to_cache_file_and_matches
    File.delete(@cache_file) if File.exist?(@cache_file)
    @l.get_lines
    @l.resolve_ips
    @l.write_temp
    @l.write_cache
    assert File.exist?(@cache_file)
    actual = YAML.load_file @cache_file
    assert_equal actual, @l.cache
  end
  
  def test_original_log_replaced_with_temp
    @l.get_lines
    @l.resolve_ips
    @l.write_temp
    @l.write_cache
    original  = File.open(@log_file).readlines
    temp    = File.open(@temp).readlines
    @l.replace_log
    new = File.open(@log_file).readlines
    assert_not_equal temp, original
    assert_equal temp, new
    assert_not_equal new, original
    assert !File.exist?(@temp)
  end
  
  def test_original_is_converted_cached_and_temp_cleaned_up
    File.delete(@temp)        if File.exist?(@temp)
    File.delete(@cache_file)  if File.exist?(@cache_file)
    assert FileUtils.compare_file("#{@log_dir}/backup.log", @log_file)
    @l.run
    assert FileUtils.compare_file("#{@log_dir}/expected.log",   @log_file)
    expected_cache = YAML.load_file("#{@log_dir}/expected.cache").length
    actual_cache = YAML.load_file("#{@log_dir}/.cache").length
    assert_equal expected_cache, actual_cache
    assert !File.exist?(@temp)
    assert File.exist?(@cache_file)
  end
  
end