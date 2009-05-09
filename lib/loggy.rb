#!/usr/bin/env ruby -w

require "resolv"
require "yaml"
require "time"

class Loggy
  VERSION     = '1.0.0'
  SEVEN_DAYS  = 604800
  TEMP_EXT    = '.temp'
  CACHE_FILE  = 'cache.yml'
  
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
    l = line.split delimiter
    raise StandardError, 'Unexpected format in log' if l == [line]
    { :ip => l[0], :info => delimiter + l[1] }
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

  def add_threads(i, log_file)
    queue = Queue.new
    barber = Thread.new do
      queue = get_lines(log_file).map! { |lines|
        queue << lines
      }
    end

    threads = (0..i-1).map {
      Thread.new do
        loop do
          row = queue.shift
          line = split_line row
          name = get_name line[:ip]
          build_temp log_file, "#{name}#{line[:info]}"
        end
      end
    }

  end


  
#   def parse_log log_file, num=nil
# 
#     log_lines = get_lines(log_file).collect! { |l|
#         @queue << l
#         line = split_line l
#         name = get_name line[:ip]
#         build_temp log_file, "#{name}#{line[:info]}"
#       }
#   end

end