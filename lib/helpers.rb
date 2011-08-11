module Helpers

  class NilClass
    def [] (*args)
      return nil
    end
  end
  
  def send_an_sms(opts={})
      puts "Sending msg [ #{CGI.escape(opts[:msg])} ] => #{opts[:number_to_msg]}"
      response = RestClient.get "http://api.tropo.com/1.0/sessions?action=create&token=#{TOKEN_ID}&number_to_msg=#{opts[:number_to_msg]}&msg=#{CGI.escape(opts[:msg])}"
      if response.eql?(200)
        puts "Msg sent HTTP/#{response.code}"
        true
      else
        puts "ERROR | HTTP/#{response.code}"
        false
      end
    end
end