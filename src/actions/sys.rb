require 'sinatra/base'

require 'src/utils/cache'
require 'src/utils/validates'

require 'src/app_msg'

class Sys < Sinatra::Base

  helpers Cache, Validates

  after do
    ActiveRecord::Base.connection.close
    headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => '*', 'Access-Control-Allow-Headers' => 'X-Requested-With,Content-Type'
  end

  get '/v1/sys/validate/time' do
    {flag: 1, params: [{timestamp: Time.new.to_i}]}.to_json
  end

  get '/v1/sys/validate/token' do

    # 校验参数
    result = validates_presence params, :account, :sign, :timestamp
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]

    # 校验签名
    result = validates_sign account: account, url: '/v1/sys/verify_token', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    response = AppMsg.success
    response.params << {expires_in: get_token_expires_in(account)}
    response.to_json

  end

  get '/v1/sys/apps/update' do
    # 校验参数
    result = validates_presence params, :version_code
    break result.failure.to_json unless result.valid?

    version_name = params[:version_name]
    version_code = params[:version_code].to_i


    config = YAML::load(File.open('config/apps.yml'))
    version_name_latest = config['version_name']

    version_code_latest = config['version_code'].to_i

    if version_code_latest > version_code
      result = AppMsg.success
      result.params << {latest: { version_name: version_name_latest, version_code: version_code_latest}, download: config['download_android']}
      break result.to_json
    end

    result = AppMsg.failure(0)
    result.cause << {"#{version_name}": 'is the latest'}
    result.to_json
  end

  get '/v1/sys/apps/download' do
    # 校验参数
    result = validates_presence params, :platform
    redirect '/v1/sys/apps/download.html' unless result.valid?

    platform = params[:platform]
    config = YAML::load(File.open('config/apps.yml'))

    if platform.match /(?i)android/
      redirect config['download_android']
    end

    if platform.match /(?i)ios/
      redirect config['download_ios']
    end

    redirect '/v1/sys/apps/download.html'
  end

end
