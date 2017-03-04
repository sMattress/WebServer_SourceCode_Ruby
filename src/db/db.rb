require 'active_record'
require 'yaml'
require 'src/utils/err_code_map'

module DB


  ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml')))

  class User < ActiveRecord::Base

    include ErrCodeMap

    has_one :info
    # has_many :bind
    has_many :platform
    # has_many :device, through: :bind

    validates :account, uniqueness:{ message: {err_code: ACCOUNT_TOKEN, cause: 'account was token'}}
    validates :account, format: {with: /\A1[34578]\d{9}\Z/, message: {err_code: ACCOUNT_INVALID, cause: 'account format was wrong'}}
    validates :password, format: {with: /\A[a-zA-Z][\w\^]{7,31}\Z/, message: {err_code: PASSWORD_FORMAT_ERROR, cause: 'password format was wrong'}}

    validates_associated :info
  end

  class Info < ActiveRecord::Base

    include ErrCodeMap

    belongs_to :user

    after_initialize :default_values

    def default_values
      self.name ||= 'NoName'
      self.sex ||= 1
      self.birthday ||= Date.today
      self.img_url ||= 'https://github.com/ZhangFly'
    end

    def birthday_must_in_range
      if birthday < Date.new(1900,01,01) || birthday > Date.today
        errors.add(:birthday, {err_code: BIRTHDAY_OUT_RANGE, case: 'must range 1900-01-01 ~ Tody'})
      end
    end

    validates :name, presence: true
    validates :sex, inclusion: {in: [0, 1, 2], message: {err_code: SEX_OUT_RANGE, cause:'sex only can be 0,1,2'}}
    # validates :img_url, format: {with: /\Ahttps?:\/\/.*\Z/, message: {err_code: IMG_URL_FORMAT_ERROR, cause: 'image url was invalid'}}
    validate :birthday_must_in_range

  end

  # class Bind < ActiveRecord::Base
  #
  #   include ErrCodeMap
  #
  #   belongs_to :user
  #   belongs_to :device
  #
  #   after_initialize :default_values
  #
  #   def default_values
  #     self.alias ||= '新设备'
  #   end
  #
  # end
  #
  # class Device < ActiveRecord::Base
  #
  #   include ErrCodeMap
  #
  #   has_many :bind
  #   has_many :user, through: :bind
  #
  #   after_initialize :default_values
  #
  #   def default_values
  #     self.name ||= 'NoName'
  #   end
  #
  # end

  class Platform < ActiveRecord::Base

    include ErrCodeMap

    belongs_to :user

    validates :open_id, uniqueness:{ message: {err_code: PLATFORM_TOKEN, cause: 'platform was token'}}

    after_initialize :default_values

    def default_values
      self.platform_type ||= 'None'
    end

  end

end
