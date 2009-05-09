require 'test/unit'
require "resolv"
require "yaml"

class Loggy
  VERSION = '1.0.0'
  CACHE_7_DAYS = 604800
  
  def initialize cache_file
    @cache = cache_file
  end
  
  def get_name ip
    if !@cache[ip]
      Resolv.getname ip
    else
      @cache[ip]['name']
    end

  end
  
  def replace_ip line
    line =~ /^(.+)\s(-\s){2}/
    line.gsub!($1, get_name($1))
  end
  
end
