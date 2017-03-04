require 'sinatra/base'

require 'src/utils/cache'
require 'src/utils/validates'

require 'src/app_msg'

class Corporation < Sinatra::Base

  helpers Cache, Validates

  after do
    ActiveRecord::Base.connection.close
    headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => '*', 'Access-Control-Allow-Headers' => 'X-Requested-With,Content-Type'
  end

  post '/v1/corporation/device/create' do
    # 校验参数
    result = validates_presence params, :device_name
    break result.failure.to_json unless result.valid?

    device_name = params[:device_name]

    # 校验设备
    result = validates_device device_name
    if result.valid?
      response = AppMsg.failure(DEVICE_TOKEN)
      response.cause << {"#{device_name}": 'was token'}
      break response.to_json
    end

    device = DB::Device.create name: device_name

    if device.valid?
      response = AppMsg.success
    else
      err = evice.errors.messages.first[1].first
      response = AppMsg.failure(err[:err_code])
      response.cause << err[:cause]
    end

    response.to_json
  end

  get '/v1/corporation/device/delete' do
    msg = AppMsg.failure(UNREALIZED_FUNCTION)
    msg.cause << {'/v1/corporation/device/delete': 'not open'}
    msg.to_json
  end

  post '/v1/corporation/device/update' do
    msg = AppMsg.failure(UNREALIZED_FUNCTION)
    msg.cause << {'/v1/corporation/device/update': 'not open'}
    msg.to_json
  end
end