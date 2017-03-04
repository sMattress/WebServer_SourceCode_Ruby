class AppMsg

  attr_accessor :flag, :err_code, :cause, :params

  private def initialize
    @flag = nil
    @err_code = nil
    @cause = nil
    @params = nil
  end

  def self.success
    success = self.new
    success.flag = 1
    success.params = []
    success
  end

  def self.failure(err_code)
    failure = self.new
    failure.flag = 0
    failure.err_code = err_code
    failure.cause = []
    failure
  end

  def to_json
    map = {}
    map[:flag] = @flag unless @flag.blank?
    map[:err_code] = @err_code unless @err_code.blank?
    map[:cause] = @cause unless @cause.blank?
    map[:params] = @params unless @params.blank?
    map.to_json
  end
end