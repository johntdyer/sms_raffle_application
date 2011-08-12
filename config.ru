%w(rubygems rest-client json sinatra tropo-webapi-ruby).each{|lib| require lib}

require './app.rb'
run Sinatra::Application