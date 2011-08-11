%w(rubygems awesome_print rest-client json sinatra tropo-webapi-ruby).each{|lib| require lib}
#TOKEN_ID='MY_TOKEN_ID'

COUCH_BASE = 'tropo.iriscouch.com'
CLOUDANT_USER = 'jdyer'
CLOUDANT_PASS = 'Lon3star!'
DB_NAME='lonestar'
TOKEN_ID='05e9077d177c1f49a997f21df0bed69f0a19332ddc25a975a29d26a5e29cc0e147235f04597b0aef595a85c3'

COUCH_URL = "http://#{CLOUDANT_USER}:#{CLOUDANT_PASS}@#{COUCH_BASE}/#{DB_NAME}"
#curl https://krumpt:password@krumpt.cloudant.com/lsrc/_all_docs

# User sends email, we log initial text and number, user can only enter once

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end


#include OperatorModule


def unique_phone_number
  true
end
  
def unique_email
  false
end

def create_record(opts={})
#  opts={:winner=>{:phone_number=>"4074740216",:email=>"john@tropo.com",:name=>"Marge Simpson"}}
#  opts={:winner=>{:phone_number=>"4074740217",:email=>"john@tropo.com",:name=>"Bart Simpson"}}

  response = RestClient.put COUCH_URL + "/" + CGI.escape(opts[:winner][:phone_number]), data={:rand=>rand.round(3)}.merge(opts).to_json,:content_type=>'application/json'
  response.code.eql?(201) ? true : false
end

def get_random_user
  JSON.parse(RestClient.get COUCH_URL+"/_design/app/_view/random?limit=1")["rows"][0]["value"]
end


def send_msg(sessions_object)
  tropo = Tropo::Generator.new do
      message({
          :to => 'tel:+1'+sessions_object[:session][:parameters][:number_to_msg],
          :channel => 'TEXT', 
          :network => 'SMS'}) do
              say     :value => sessions_object[:session][:parameters][:msg]
           end
  end
      tropo
end

def receive_msg
   tropo = Tropo::Generator.new do
      on :event => 'continue', :next => '/hangup'
      if unique_phone_number && unique_email
        say 'Got it thanks'
      else
        say "stop trying to cheat, one entry per number"
      end
    end
    tropo
end

post '/msg' do
  sessions_object = Tropo::Generator.parse request.env['rack.input'].read
  p sessions_object
  tropo = sessions_object["session"]["initial_text"] ? receive_msg() : send_msg(sessions_object) 
  tropo.response
end

# post '/initial_text' do
#     sessions_object = Tropo::Generator.parse request.env['rack.input'].read
#     initial_text=sessions_object["session"]["initial_text"]
# 
#     tropo = Tropo::Generator.new do
#       on :event => 'continue', :next => '/hangup'
#       if unique_phone_number && unique_email
#         say 'Got it thanks'
#       else
#         say "stop trying to cheat, one entry per number"
#       end
#     end
#  tropo.response
# end

post '/hangup.json' do
   'Received a hangup response!'
   json_string = request.env["rack.input"].read
   tropo_session = Tropo::Generator.parse json_string
   p tropo_session
end

get "/" do 
  haml :root
end

# get '/test' do 
#   create_record(:winner=>{:phone_number=>"407-474-0214",:email=>"john@tropo.com",:name=>"Homer Simpson"})
# end

post '/get_winner' do
  get_random_user.to_json
  #{:winner=>{:phone_number=>"407-474-0214",:email=>"john@tropo.com",:name=>"Homer Simpson"}}.to_json
end
get '/pick_winner' do 
  haml :winner
end

post "/send_notification" do 
  send_sms :number_to_msg=>"4074740214", :msg => "You won, come to the front and show this text msg to claim your prize [Tropo Rox]"
end
# 
# post '/send_message.json' do  
#   
#   sessions_object = Tropo::Generator.parse request.env['rack.input'].read 
#   
#     session[:message] = sessions_object[:session][:parameters][:message]
#     
#    
#     puts sessions_object  #Log to sinatra console
#          tropo = Tropo::Generator.new do  
#             on :event => 'continue', :next => '/response.json'
#                  call({
#                    :to => 'tel:+1'+sessions_object[:session][:parameters][:user_number],
#                    :from=>sessions_object[:session][:parameters][:operator_number],
#                    :channel => 'TEXT', 
#                    :network => 'SMS'})
#                     ask({ :name    => 'air_speed', 
#                            :bargein => 'true', 
#                            :timeout => 900.0,
#                            :require => 'true' }) do
#                              say     :value =>  sessions_object[:session][:parameters][:message]
#                              choices :value => '[ANY]'
#                            end
#                    end
#                     
#                  puts tropo.response
#                  tropo.response
# end
# 
# post '/ask.json' do
#   sessions_object = Tropo::Generator.parse request.env['rack.input'].read
#    puts sessions_object  #Log to sinatra console
# 
# 
#     tropo = Tropo::Generator.new do
#               on :event => 'hangup', :next => '/hangup.json'
#               on :event => 'continue', :next => '/answer.json'
#               ask({ :name    => 'msg', 
#                     :bargein => 'true', 
#                     :timeout => 900.0,
#                     :require => 'true' }) do
#                       say     :value =>  session[:message]
#                       choices :value => '[ANY]'
#                     end
#             end
#     tropo.response
# end      
# 
# post '/answer.json' do
#   tropo_event = Tropo::Generator.parse request.env["rack.input"].read
#   p tropo_event
# end
# 
# post '/hangup.json' do
#   p 'Received a hangup response!'
#   json_string = request.env["rack.input"].read
#   tropo_session = Tropo::Generator.parse json_string
#   p tropo_session
# end
