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
    @log_lines  = []
    @dir        = File.split(@org)[0]
    
    if yaml_obj
      @cache    = yaml_obj
    else
      @cache    = prepare_cache    
    end
  end
  
  def run
    get_lines
    resolve_ips
    write_temp
    write_cache
    replace_log
  end

  def get_lines
    lines = open_log_file(@org).readlines
    raise StandardError, 'Log File is empty' if lines.empty?
    lines.each do |line|
      n = @log_lines.length
      @log_lines[n] = split_up line
    end
  end
  
  def write_temp
    File.delete(@temp) if File.exist?(@temp)
    @log_lines.each do |line|
      build_temp "#{line[:ip]}#{line[:request]}"
    end
  end

  def resolve_ips
    @log_lines.each do |line|
      ip = line[:ip]
      if !@cache[ip] || Time.parse(@cache[ip]['expire'].to_s) < Time.now - SEVEN_DAYS
        @cache[ip] = {}
        dns = ip
        begin
          timeout(0.5){
            dns = Resolv.getname ip
          }
        rescue Timeout::Error, Resolv::ResolvError
          dns = "#{ip}"
        end
        @cache[ip]['name']    = dns
        @cache[ip]['expire']  = Time.now.to_s
      end
      line[:ip] = @cache[ip]['name']
    end
  end

  def open_log_file path
    if File.exist? path
      File.open path, 'r+'
    else
      raise StandardError, 'File was not found'
    end
  end
  
  def split_up line
    delimiter = " - - "
    l = line.split(delimiter)
    raise StandardError, 'Unexpected format in log' if l == [line]
    { :ip => "#{l[0]}", :request => "#{delimiter}#{l[1]}" }
  end

  def prepare_cache
    cache = "#{@dir}/#{CACHE_FILE}"
    #4 Create Cache if it doesn't exist
    File.open(cache , 'a+') if !File.exist?(cache)
    YAML.load_file(cache)
  end
  
  def write_cache
    cache = "#{@dir}/#{CACHE_FILE}"
    File.open(cache, 'w' ) do |out|
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

# 
#   def add_threads(i, log_file)
#     n = thread_limit i
#     get_lines(log_file).map! { |lines|
#       @queue << lines
#     }
# 
#     thread_pool = Array.new
# 
#     n.times{
#       thread_pool << Thread.new do
#         until @queue.empty?
#           row = @queue.pop
#           line = split_line row
#           name = get_name line[:ip]
#           build_temp log_file, "#{name}#{line[:info]}"
#         end
#       end
#     }
#     thread_pool.each { |t| t.join }
#     #replace_log log_file
#   end  

end

# Loggy.new(ARGV[0], ARGV[1])if $0 == __FILE__
new = Loggy.new(1, '../test/log/big_backup.log') if $0 == __FILE__
new.run if $0 == __FILE__
