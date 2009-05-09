#!/usr/bin/env ruby -w

require "resolv"
require "yaml"
require "time"

class Loggy
  VERSION     = '1.0.0'
  SEVEN_DAYS  = 604800
  TEMP_EXT    = '.temp'
  CACHE_FILE  = 'cache.yml'
  MAX_THREADS = 100
  
  def initialize cache_file=nil
    @cache = cache_file
    @queue = Queue.new
  end
  
  def get_name ip
    unless @cache[ip] && Time.parse(@cache[ip]['expire']) > Time.now - SEVEN_DAYS
      @cache[ip] = {}
      @cache[ip]['name'] = Resolv.getname ip
      @cache[ip]['expire'] = Time.now
    end
    @cache[ip]['name']
  end
  
  def replace_ip line
    line =~ /^(.+)\s(-\s){2}/
    line.gsub!($1, get_name($1))
  end
  
  def split_line line
    delimiter = ' - - '
    l = line.split(delimiter).sort
    raise StandardError, 'Unexpected format in log' if l == [line]
    { :ip => "#{l[0]}", :info => "#{delimiter}#{l[1]}" }
  end
  
  def open_file path
    if File.exist? path
      File.open path, 'r+'
    else
      raise StandardError, 'File was not found'
    end
  end
  
  def get_lines path
    lines = open_file(path).readlines
    raise StandardError, 'Log File is empty' if lines.empty?
    lines
  end
  
  def build_temp org, line
    temp = org + TEMP_EXT
    File.open(temp, 'a+') { |f|
      f.write("#{line}")
    }
  end
  
  def delete_temp org
    temp = org + TEMP_EXT
    raise StandardError, 'File does not exist to delete' if !File.exist?(temp)
    File.delete(temp)
  end
  
  def thread_limit i=nil
    if i == nil || i > MAX_THREADS
      MAX_THREADS
    else
      i
    end
  end

  def add_threads(i, log_file)
    n = thread_limit i
    get_lines(log_file).map! { |lines|
      @queue << lines
    }

    thread_pool = Array.new

    n.times{
      thread_pool << Thread.new do
        until @queue.empty?
          row = @queue.pop
          line = split_line row
          name = get_name line[:ip]
          build_temp log_file, "#{name}#{line[:info]}"
        end
      end
    }
    thread_pool.each { |t| t.join }
  end
  
  def replace_log org
    temp = org + TEMP_EXT
    File.delete(org)
    File.rename(temp, org)
  end

end