require 'test/unit'
require "resolv"
require "yaml"

class Loggy
  VERSION = '1.0.0'
  
  def get_name ip
    Resolv.getname ip
  end
  
  def replace_ip line
    line =~ /^(.+)\s(-\s){2}/
    line.gsub!($1, get_name($1))
  end  
  
end
