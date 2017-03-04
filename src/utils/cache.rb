require 'redis'

module Cache

  Redis.current = Redis.new host: '127.0.0.1', port: 6379

  def set_code(account, code)
    Redis.current.set 'Code: ' + account, code, {nx: 'NX', ex: 60}
  end

  def get_code(account)
    code = Redis.current.get 'Code: ' + account
    if code.blank?
      code = rand(999999)
      set_code account, code
    end
    code
  end

  def remove_code(account)
    Redis.current.del('Code: ' + account) if Redis.current.exists('Code: ' + account)
  end

  def set_token(account, token)
    Redis.current.set 'Token: ' + account, token, {ex: 30 * 24 * 60 * 60}
  end

  def get_token(account)
    Redis.current.get 'Token: ' + account
  end

  def make_token(account)
    token = get_token account
    if token.blank?
      token = SecureRandom.urlsafe_base64
      set_token account, token
    else
      refresh_token account
    end
    token
  end

  def refresh_token(account)
    Redis.current.expire 'Token: ' + account, 30 * 24 * 60 * 60
  end

  def remove_token(account)
    Redis.current.del('Token: ' + account) if Redis.current.exists('Token: ' + account)
  end

  def get_token_expires_in(account)
    Redis.current.ttl 'Token: ' + account
  end
end
