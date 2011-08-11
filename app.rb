$LOAD_PATH << './lib' 

%w(rubygems awesome_print rest-client helpers json sinatra tropo-webapi-ruby).each{|lib| require lib}
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


include Helpers

#  opts={:phone_number=>"4075551005",:email=>"Marge@tropo.com",:name=>"Stan Simpson"}; create_record(opts);opts={:phone_number=>"4075551001",:email=>"Bart@tropo.com",:name=>"Bart Simpson"}; create_record(opts);opts={:phone_number=>"4075551002",:email=>"Homer@tropo.com",:name=>"Homer Simpson"}; create_record(opts);opts={:phone_number=>"4075551009",:email=>"col@tropo.com",:name=>"Blah Simpson"}; create_record(opts)
# opts={:phone_number=>"4075551007",:email=>"New@tropo.com",:name=>"newer Simpson"}; create_record(opts)

def create_record(opts={})
  begin
    response = RestClient.put COUCH_URL + "/" + CGI.escape(opts[:phone_number]), data={:rand=>rand.round(3)}.merge(opts).to_json,:content_type=>'application/json'
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
    update_record = RestClient.put COUCH_URL + "/" + CGI.escape(winner_record[0]["value"]["phone_number"]), data={:has_won=>true,:_rev=>winner_record[0]["value"]["_rev"]}.merge(winner_record[0]["value"]).to_json,:content_type=>'application/json' 
    update_record.code.eql?(201) ? winner_record[0]["value"] : "error"
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
      if create_record(:phone_number=>sessions_object[:session][:from][:id])
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
  tropo = sessions_object["session"]["initial_text"] ? receive_msg(sessions_object) : send_msg(sessions_object) 
  tropo.response
end

post '/hangup.json' do
   'Received a hangup response!'
   json_string = request.env["rack.input"].read
   tropo_session = Tropo::Generator.parse json_string
   p tropo_session
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

get "/send_notification" do 
  send_sms :number_to_msg=>"14074740214", :msg => "You won, come to the front and show this text msg to claim your prize [Tropo Rox]"
end
