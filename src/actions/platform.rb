require 'sinatra/base'

require 'open-uri'

require 'src/utils/cache'
require 'src/utils/validates'

require 'src/app_msg'

class Platform < Sinatra::Base

  helpers Cache, Validates

  after do
    ActiveRecord::Base.connection.close
    headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => '*', 'Access-Control-Allow-Headers' => 'X-Requested-With,Content-Type'
  end

  post '/v1/platform/register' do

    # 校验参数
    result = validates_presence params, :account, :open_id, :password, :type
    break result.failure.to_json unless result.valid?

    account = params[:account]
    open_id = params[:open_id]
    password = params[:password]
    type = params[:type]

    # 校验用户
    result = validates_user account
    break result.failure.to_json unless result.valid?

    user = result.success

    # 校验密码
    result = validates_password account, password
    break result.failure.to_json unless result.valid?

    if user.platform.exists? platform_type: type
      platform = user.platform.find_by(platform_type: type).first
      platform.update open_id: open_id
    else
      platform = user.platform.create open_id: open_id, platform_type: type
      platform.save
    end

    if platform.valid?
      msg = AppMsg.success
    else
      err = platform.errors.messages.first[1].first
      msg = AppMsg.failure(err[:err_code])
      msg.cause << err[:cause]
    end

    msg.to_json

  end

  get '/v1/platform/login' do

    # 校验参数
    result = validates_presence params, :open_id, :access_token, :type
    break result.failure.to_json unless result.valid?

    open_id = params[:open_id]
    access_token = params[:access_token]
    type = params[:type]

    unless type.match /(?i)wechat/
      msg = AppMsg.failure(PLATFORM_INVALID)
      msg.cause << {"#{type}": 'was invalid platform'}
      break msg.to_json
    end

    # # 微信服务器验证
    # url = "https://api.weixin.qq.com/sns/auth?access_token=#{access_token}&openid=#{open_id}"
    # html_response = nil
    # open(url) do |http|
    #   html_response = http.read.to_json
    # end
    #
    # unless html_response['errcode'] == 0
    #   msg = AppMsg.failure(17)
    #   msg.cause << html_response
    #   break msg.to_json
    # end

    platform = DB::Platform.find_by open_id: open_id

    if platform.blank?
      msg = AppMsg.failure(PLATFORM_ERR)
      msg.cause << {"#{open_id}": 'invalid id'}
      break msg.to_json
    end

    user = DB::User.find platform.user_id

    if user.blank?
      msg = AppMsg.failure(PLATFORM_ERR)
      msg.cause << {"#{open_id}": 'invalid id'}
      break msg.to_json
    end

    msg = AppMsg.success
    token = get_token(user.account)
    token = make_token(user.account) if token.blank?
    msg.params << {token: token, expires_in: get_token_expires_in(user.account), account: user.account, user_id: user.id}
    msg.to_json

  end

end