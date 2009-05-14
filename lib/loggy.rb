require 'resolv'
require 'yaml'
require 'time'
require 'fileutils'

# Took 7:24 on big log first run
# Took 38 seconds second time
# Took 1 min third time

class Loggy

  TEMP_EXT      = '.temp'
  CACHE_FILE    = '.cache'
  SEVEN_DAYS    = 604800
  MAX_THREADS   = 100
  
  attr_accessor :cache, :log_lines, :threads, :dir

  def initialize threads, log_file, yaml_obj=nil
    @threads    = set_limit threads
    @org        = log_file
    @temp       = @org + TEMP_EXT
    @log_lines  = Array.new
    @dir        = File.split(@org)[0]
    @queue      = Queue.new
    @t_pool     = Array.new
    if yaml_obj
      @cache    = yaml_obj
    else
      @cache    = prepare_cache    
    end
  end
  
  def run
    File.delete(@temp) if File.exist?(@temp)
    get_lines
    add_threads
    write_cache
    replace_log
  end

  def get_lines
    File.open(@org, 'r+').readlines.each do |line|
      @log_lines << line
    end
  end
  
  def add_threads
    @log_lines.each do |line|
      @queue << line
    end
    @threads.times{
      @t_pool << Thread.new do
        until @queue.empty?
          build_temp resolve_ip( split_up( @queue.pop ) )
        end
      end
    }
    @t_pool.each{ |t| t.join }
  end

  def resolve_ip line
    dns = ip = line[:ip]
    if !@cache[ip] || Time.parse(@cache[ip]['expire'].to_s) < Time.now - SEVEN_DAYS
      begin
        dns   = Resolv.getname ip
      rescue Timeout::Error, Resolv::ResolvError
        dns   = "#{ip}"
      end
      @cache[ip]            = {}
      @cache[ip]['name']    = dns
      @cache[ip]['expire']  = Time.now.to_s
    end
    "#{@cache[ip]['name']}#{line[:request]}"
  end
  
  def split_up line
    delimiter = " - - "
    l = line.split(delimiter)
    raise StandardError, 'Unexpected format in log' if l == [line]
    { :ip => "#{l[0]}", :request => "#{delimiter}#{l[1]}" }
  end

  def prepare_cache
    cache = "#{@dir}/#{CACHE_FILE}"
    # Need a better way to create a file
    File.open(cache , 'a+') if !File.exist?(cache)
    YAML.load_file(cache)
  end
  
  def write_cache
    File.open("#{@dir}/#{CACHE_FILE}", 'w' ) do |out|
      YAML.dump( @cache, out )
    end
  end
  
  def build_temp line
    File.open(@temp, 'a+') { |f|
      f.puts "#{line}"
    }
  end
  
  def replace_log
    File.delete(@org)
    FileUtils.mv(@temp, @org)
  end
  
  def set_limit i=nil
    if i == nil || i > MAX_THREADS
      MAX_THREADS
    else
      i
    end
  end

end

# new = Loggy.new(1, '../test/log/big_backup.log') if $0 == __FILE__
# new.run if $0 == __FILE__
