#!/usr/bin/env ruby -w

require "resolv"
require "yaml"
require "time"

class Loggy
  VERSION     = '1.0.0'
  SEVEN_DAYS  = 604800
  TEMP    = '.temp'
  
  def initialize cache_file=nil
    @cache = cache_file
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
    temp = org + TEMP
    File.open(temp, 'a+') { |f|
      f.write("#{line}")
    }
  end
  
  def delete_temp org
    temp = org + TEMP
    raise StandardError, 'File does not exist to delete' if !File.exist?(temp)
    File.delete(temp)
  end

end