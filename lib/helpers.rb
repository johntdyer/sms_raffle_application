module Helpers
  def send_an_sms(opts={})
      puts "Sending msg [ #{CGI.escape(opts[:msg])} ] => #{opts[:number_to_msg]}"
      response = RestClient.get "http://api.tropo.com/1.0/sessions?action=create&token=#{$config["tropo"]["token_id"]}&number_to_msg=#{opts[:number_to_msg]}&msg=#{CGI.escape(opts[:msg])}"
      if response.eql?(200)
        puts "Msg sent HTTP/#{response.code}"
        true
      else
        puts "ERROR | HTTP/#{response.code}"
        false
      end
    end
    
    def create_record(opts={})
      begin
        data={
            :rand=>rand
          }.merge(opts)

        response = RestClient.put COUCH_URL + "/" + CGI.escape(opts[:phone_number]), data.to_json,:content_type=>'application/json'
        puts response
        response.code.eql?(201) ? true : false
      rescue RestClient::Conflict
        false
      end
    end

    def get_random_user
        winner_record = JSON.parse(RestClient.get COUCH_URL+"/_design/app/_view/random?limit=1")["rows"]#["value"]
      if winner_record.empty?
        nil
      else
         session[:winning_record] = winner_record[0]["value"]
         session[:winner_candidate_url] = COUCH_URL + "/" + CGI.escape(winner_record[0]["value"]["phone_number"])
         session[:winner_candidate_data]= {:has_won=>true,:_rev=>winner_record[0]["value"]["_rev"]}.merge(winner_record[0]["value"])
      end
    end

    def send_msg(sessions_object)
      tropo = Tropo::Generator.new do
          message({
              :to => "tel:+#{sessions_object[:session][:parameters][:number_to_msg]}",
              :channel => 'TEXT', 
              :network => 'SMS'}) do
                  say     :value => sessions_object[:session][:parameters][:msg]
               end
      end
      tropo
    end

    def receive_msg(sessions_object)
       tropo = Tropo::Generator.new do
          on :event => 'continue', :next => '/hangup'
            if sessions_object["session"]["initial_text"].split(",").length.eql?(2)
              if create_record({:phone_number=>sessions_object[:session][:from][:id],:user_name=>sessions_object["session"]["initial_text"].split(",")[0].chomp,:email=>sessions_object["session"]["initial_text"].split(",")[1].chomp})
                say 'Got it thanks'
              else
                say "stop trying to cheat, one entry per number"
              end
            else
              say "I didn't understand you, please use this format: 
              <name>,<email>"
            end
        end
        tropo
    end
    
    
end