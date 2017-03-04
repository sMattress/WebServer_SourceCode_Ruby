require 'digest/md5'

require 'src/app_msg'

require 'src/db/db'

require 'src/utils/err_code_map'

require 'net/http'

require 'json'


module Validates

  include ErrCodeMap

  class Result

    attr_accessor :success, :failure

    def initialize
      @valid = true
      @success = nil
      @failure = nil
    end

    def valid?
      @valid
    end

    def valid=(valid)
      @valid = valid
    end

  end

  def validates_sms(account, code, platform)

    result = Result.new

    uri = URI("https://webapi.sms.mob.com/sms/verify")
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(uri)
      app_key = ''
      app_key = '1b7e634a3263c' if platform == 'ios'
      app_key = '1b728173e3684' if platform == 'android'
      req.body = "appkey=#{app_key}&phone=#{account}&zone=86&code=#{code}"
      http.request(req)

    end

    res_code = JSON.parse(res.body)['status']

    unless res_code == 200
      result.valid = false
      result.failure = AppMsg.failure(res_code)
    end
    result
  end

  def validates_presence(params, *attrs)
    result = Result.new
    msg = AppMsg.failure(LACK_NECESSARY_PARAMS)

    attrs.each do |attr|
      if params[attr].blank?
        result.valid = false
        msg.cause << {"#{attr}": 'can not be absence'}
      end
    end

    unless result.valid?
      result.failure = msg
    end
    result
  end

  def validates_user(account)
    result = Result.new
    user = DB::User.find_by account: account

    if user.blank?
      result.valid = false
      msg = AppMsg.failure(ACCOUNT_INVALID)
      msg.cause << {"#{account}": 'was invalid account'}
      result.failure = msg
    else
      result.success = user
    end
    result
  end

  def validates_device(device_name)
    result = Result.new
    device = DB::Device.find_by name: device_name
    if device.blank?
      result.valid = false
      msg = AppMsg.failure(DEVICE_INVALID)
      msg.cause << {"#{device_name}": 'was invalid device'}
      result.failure = msg
    else
      result.success = device
    end
    result
  end

  def validates_sign(params)
    account = params[:account]
    url = params[:url]
    timestamp = params[:timestamp].to_i
    sign = params[:sign]

    result = Result.new
    result.failure = AppMsg.failure(SIGN_INVALID)

    if (Time.new.to_i - timestamp).abs > 30
      result.valid = false
      result.failure.cause << {"#{sign}": 'was invalid sign'}
      return result
    end

    token = get_token account

    if account.blank?
      result.valid = false
      result.failure.cause << {"#{sign}": 'was invalid sign'}
      return result
    end

    real_sign = Digest::MD5.hexdigest "#{url}?account=#{account}&timestamp=#{timestamp}&token=#{token}"

    unless real_sign == sign
      result.valid = false
      result.failure.cause << {"#{sign}": 'was invalid sign'}
    end
    result
  end

  def validates_secure_password(account, password)
    result = Result.new

    user = DB::User.find_by account: account
    code = get_code account
    remove_code account
    real_password = Digest::MD5.hexdigest user.password + code.to_s

    unless real_password == password
      result.valid = false
      msg = AppMsg.failure(PASSWORD_INVALID)
      msg.cause << {"#{password}": 'was invalid password'}
      result.failure = msg
    end
    result
  end

  def validates_password(account, password)
    result = Result.new

    user = DB::User.find_by account: account

    unless user.password == password
      result.valid = false
      msg = Result.failure(PASSWORD_INVALID)
      msg.cause << {"#{password}": 'was invalid password'}
      result.failure = msg
    end
    result
  end

end
