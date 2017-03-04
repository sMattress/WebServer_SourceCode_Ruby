$LOAD_PATH << '.'

require 'sinatra/base'

require 'rack/contrib'

require 'src/actions/sys'
require 'src/actions/user'
require 'src/actions/corporation'
require 'src/actions/platform'

class RemoteCtrlServer < Sinatra::Application

  use Rack::PostBodyContentTypeParser

  use Sys
  use User
  use Corporation
  use Platform

  set :public_folder, './static'
  set :static, true

  options '*' do
    headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => '*', 'Access-Control-Allow-Headers' => 'X-Requested-With,Content-Type'
  end

  get '/' do
    redirect 'http://smartmattress.lesmarthome.com/index.html'
  end

  get '/index.html' do
    redirect 'http://smartmattress.lesmarthome.com/index.html'
  end

  error 400..510 do
    'boom'
  end
end
