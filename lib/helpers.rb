module Helpers

    def send_sms(opts={})
      puts "Sending msg [ #{opts[:msg]} ] => #{opts[:number_to_msg]}"
      uri = URI.parse("http://api.tropo.com/1.0/sessions?action=create&token=#{TOKEN_ID}&user_number=#{opts[:number_to_msg]}&msg=#{opts[:msg]}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request) 
      if response.code != 200
        puts "ERROR | HTTP/#{response.code}"
        true
      else
        puts "Msg sent HTTP/#{response.code}"
        false
    end
    
end