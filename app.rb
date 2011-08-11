$LOAD_PATH << './lib' 
%w(rubygems yaml awesome_print rest-client helpers json sinatra tropo-webapi-ruby).each{|lib| require lib}


begin
  $config = YAML::load(File.read("./config/config.yml"))
rescue Error::ENOENT
  puts "Did you rename the config_example.yml file to config.yml?"
  exit!
end



#$config = YAML::load(File.read("./config/config.yaml"))

COUCH_URL = "http://#{$config["couch"]["user"]}:#{$config["couch"]["pass"]}@#{$config["couch"]["base_url"]}/#{$config["couch"]["db_name"]}"

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

include Helpers
enable :sessions

#  opts={:phone_number=>"4075551dsd005",:email=>"Marge@tropo.com",:name=>"Stan Simpson"}; create_record(opts);opts={:phone_number=>"4075551001",:email=>"Bart@tropo.com",:name=>"Bart Simpson"}; create_record(opts);opts={:phone_number=>"4075551002",:email=>"Homer@tropo.com",:name=>"Homer Simpson"}; create_record(opts);opts={:phone_number=>"4075551009",:email=>"col@tropo.com",:name=>"Blah Simpson"}; create_record(opts)
# opts={:phone_number=>"14074740214",:email=>"Marge@tropo.com",:name=>"Stan Simpson"}; create_record(opts)
# create_record :phone_number=>"14074740214",:user_name=>"john",:email=>"john@krumpt.com"


post '/msg' do
  sessions_object = Tropo::Generator.parse request.env['rack.input'].read
  puts sessions_object
  tropo = sessions_object["session"]["initial_text"] ? receive_msg(sessions_object) : send_msg(sessions_object) 
  tropo.response
end

post '/hangup' do
   puts Tropo::Generator.parse request.env["rack.input"].read
   Tropo::Generator.on({ :event => 'hangup' }).response
end

get "/" do 
  haml :root
end

post '/get_winner' do
  a = [get_random_user.to_json] 
end

get '/pick_winner' do 
  haml :winner
end

get '/registrations' do 
  @registrations = JSON.parse(RestClient.get "#{COUCH_URL}/_all_docs?include_docs=true")["rows"]
  puts @registrations
  haml :registrations
end

post "/send_notification" do 
  if session[:winner_candidate_data]
    update_record = RestClient.put session[:winner_candidate_url],session[:winner_candidate_data].to_json,:content_type=>'application/json' 
    update_record.code.eql?(201) ? session[:winner_record] : "error"     
    send_an_sms :number_to_msg=>params["phone_number"], :msg => "Hey #{params["user_name"]} you won something cool!!! Come to the front and show this text msg to claim your prize [Tropo Rox]"
  else
    false
  end
end
