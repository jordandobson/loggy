require 'test/unit'
require 'resolv'

class Loggy
  VERSION = '1.0.0'
  
  def get_name ip
    Resolv.getname ip
  end
  
  def replace_ip line
  
  end  
  
end
