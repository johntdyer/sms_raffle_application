module Helpers
  TOKEN_ID='MY_TOKEN_ID'

    def send_sms(msg,user_number)
      puts "Sending msg [ #{msg} ] => #{user_number}"
      uri = URI.parse("http://api.tropo.com/1.0/sessions?action=create&token=#{TOKEN_ID}&user_number=#{user_number}&msg=#{msg}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request) 
      if response.code != 200
        puts "ERROR | HTTP/#{response.code}"
      else
      puts "Msg sent HTTP/#{response.code}"
    end
    
end