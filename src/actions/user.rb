require 'sinatra/base'

require 'src/utils/cache'
require 'src/utils/validates'
require 'src/utils/err_code_map'

require 'src/app_msg'

class User < Sinatra::Base

  helpers Cache, Validates, ErrCodeMap

  after do
    ActiveRecord::Base.connection.close
    headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => '*', 'Access-Control-Allow-Headers' => 'X-Requested-With,Content-Type'
  end

  get '/v1/user/code' do

    # 校验参数
    result = validates_presence params, :account
    break result.failure.to_json unless result.valid?

    account = params[:account]

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    # 生成验证码
    msg = AppMsg.success
    msg.params << {code: get_code(account).to_i}
    msg.to_json

  end

  post '/v1/user/register' do

    # 校验参数
    result = validates_presence params, :account, :password
    break result.failure.to_json unless result.valid?

    account = params[:account]
    password = params[:password]
    #sms = params[:sms]

    # # 校验短信验证码
    # result = validates_sms account, sms
    # break result.failure.to_json unless result.valid?

    # 创建用户
    user = DB::User.new account: account, password: password
    user.build_info
    user.save

    if user.valid?
      msg = AppMsg.success
      msg.params << {user_id: user.id}
    else
      err = user.errors.messages.first[1].first
      puts user.errors
      puts err
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json
  end

  get '/v1/user/login' do

    # 校验参数
    result = validates_presence params, :account, :password
    break result.failure.to_json unless result.valid?

    account = params[:account]
    password = params[:password]

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 校验安全密码
    result = validates_secure_password account, password
    break result.failure.to_json unless result.valid?

    # 生成token
    msg = AppMsg.success
    msg.params << {token: make_token(account), expires_in: get_token_expires_in(account), user_id: user.id}
    msg.to_json

  end

  get '/v1/user/logout' do
    result = validates_presence params, :account, :timestamp, :sign
    break result.failure.to_json unless result.valid?

    account = params[:account]
    timestamp = params[:timestamp]
    sign = params[:sign]


    # 校验签名
    result = validates_sign account: account, url: '/v1/user/logout', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    remove_token account

    AppMsg.success.to_json
  end

  get '/v1/user/get/base_info' do

    # 校验参数
    result = validates_presence params, :account, :timestamp, :sign
    break result.failure.to_json unless result.valid?

    account = params[:account]
    timestamp = params[:timestamp]
    sign = params[:sign]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/get/base_info', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    msg = AppMsg.success
    msg.params << user.info
    msg.to_json

  end

  get '/v1/user/get/secure_info' do

    # 校验参数
    # result = validates_presence params, :account, :timestamp, :sign,
    # break result.failure.to_json unless result.valid?

    msg = AppMsg.failure(UNREALIZED_FUNCTION)
    msg.cause << {'/v1/user/get/secure_info': 'was unrealized'}
    msg.to_json
  end

  post '/v1/user/update/base_info' do

    # 校验参数
    result = validates_presence params, :account, :timestamp, :sign
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/update/base_info', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 更新数据库
    user_info = user.info
    user_info.update(name: params[:name]) unless params[:name].blank?
    user_info.update(birthday: params[:birthday]) unless params[:birthday].blank?
    user_info.update(sex: params[:sex]) unless params[:sex].blank?

    img_type = params[:img_type]
    img_data = params[:img_data]

    unless img_data.blank?
      puts img_data
      img_url = "/icons/#{account}.#{img_type.blank? ? 'png' : img_type}"
      file = File.open("/APP/remote-ctrl-server/static/#{img_url}", 'w+')

      file.write(img_data)
      file.close
      user_info.update(img_url: "https://smartmattress.lesmarthome.com#{img_url}")
    end

    if user_info.valid?
      msg = AppMsg.success
    else
      err = user_info.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json

  end

  post '/v1/user/forget/secure_info' do

    # 校验参数
    result = validates_presence params, :account, :sms, :new_password, :platform
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sms = params[:sms]
    platform = params[:platform]

    # # 校验签名
    # result = validates_sign account: account, url: '/v1/user/update/secure_info', sign: sign, timestamp: timestamp
    # break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 校验密码
    result = validates_sms account, sms, platform
    break result.failure.to_json unless result.valid?

    user.update(password: params[:new_password]) unless params[:new_password].blank?

    if user.valid?
      msg = AppMsg.success
    else
      err = user.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json
  end


  post '/v1/user/update/secure_info' do

    # 校验参数
    result = validates_presence params, :account, :timestamp, :sign, :old_password
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]
    old_password = params[:old_password]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/update/secure_info', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 校验密码
    result = validates_password account, old_password
    break result.failure.to_json unless result.valid?

    user.update(password: params[:new_password]) unless params[:new_password].blank?

    if user.valid?
      msg = AppMsg.success
    else
      err = user.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json
  end

  post '/v1/user/device/bind' do

    # 校验参数
    result = validates_presence params, :account, :sign, :timestamp, :device_name
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]
    device_name = params[:device_name]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/device/bind', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 校验设备
    result = validates_device device_name
    break result.failure.to_json unless result.valid?

    device = result.success

    if user.device.exists? device.id
      msg = AppMsg.failure(DEVICE_TOKEN)
      msg.cause << 'the device was bind early'
      break msg.to_json
    end

    bind = user.bind.create device_id: device.id

    if bind.valid?
      msg = AppMsg.success
    else
      err = bind.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json
  end

  post '/v1/user/device/unbind' do

    # 校验参数
    result = validates_presence params, :account, :sign, :timestamp, :device_name
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]
    device_name = params[:device_name]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/device/unbind', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 校验设备
    result = validates_device device_name
    break result.failure.to_json unless result.valid?

    device = result.success

    unless user.device.exists? id: device.id
      msg = AppMsg.failure(DEVICE_INVALID)
      msg.cause << {"#{device_name}": 'unbind device'}
      break msg.to_json
    end

    bind = user.bind.find_by device_id: device.id
    user.bind.destroy bind

    if bind.valid?
      AppMsg.success.to_json
    else
      err = bind.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

  end

  get '/v1/user/device/list' do

    # 校验参数
    result = validates_presence params, :account, :sign, :timestamp
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/device/list', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    devices = user.device.includes(:bind).map do |d|
      {id: d.id, device_name: d.name, alias: d.bind.find_by(user_id: user.id).alias}
    end

    msg = AppMsg.success
    msg.params = devices
    msg.to_json

  end

  post '/v1/user/device/update' do

    # 校验参数
    result = validates_presence params, :account, :device_name, :sign, :timestamp
    break result.failure.to_json unless result.valid?

    account = params[:account]
    sign = params[:sign]
    timestamp = params[:timestamp]
    device_name = params[:device_name]

    # 校验签名
    result = validates_sign account: account, url: '/v1/user/device/update', sign: sign, timestamp: timestamp
    break result.failure.to_json unless result.valid?

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    device = user.device.find_by name: device_name

    if device.blank?
      msg = AppMsg.failure(DEVICE_INVALID)
      msg.cause << {"#{device_name}": 'invalid device'}
      break msg.to_json
    end

    bind = user.bind.find_by device_id: device.id
    bind.update(alias: params[:alias].encode('utf-8')) unless params[:alias].blank?

    if bind.valid?
      msg = AppMsg.success
    else
      err = bind.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json
  end

end
