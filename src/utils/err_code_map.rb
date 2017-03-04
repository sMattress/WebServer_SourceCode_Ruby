module ErrCodeMap

  # 无错误
  NONE = 0x00                   # Dec:  0 无错误

  # 请求阶段
  LACK_NECESSARY_PARAMS = 0x01  # Dec:  1 缺失必要参数
  SIGN_INVALID = 0x02           # Dec:  2 签名无效

  # 执行阶段
  ACCOUNT_TOKEN = 0x10          # Dec: 16 账号已存在
  ACCOUNT_INVALID = 0x11        # Dec: 17 账号不存在
  DEVICE_TOKEN = 0x12           # Dec: 18 设备已存在
  DEVICE_INVALID = 0x13         # Dec: 19 设备不存在
  ACCOUNT_FORMAT_ERROR = 0x14   # Dec: 20 账号格式错误
  PASSWORD_FORMAT_ERROR= 0x15   # Dec: 21 密码格式错误
  PASSWORD_INVALID = 0x16       # Dec: 22 密码无效
  SEX_OUT_RANGE = 0x17          # Dec: 23 性别取值超出范围
  BIRTHDAY_OUT_RANGE = 0x18     # Dec: 24 生日取值超出范围
  IMG_URL_FORMAT_ERROR = 0x19   # Dec: 25 图像连接格式错误
  PLATFORM_TOKEN = 0x1A         # Dec: 26 第三方平台已绑定
  PLATFORM_INVALID = 0x1B       # Dec: 27 无效的第三方平台
  PLATFORM_ERR = 0x1C           # Dec: 28 错误的第三方消息

  UNREALIZED_FUNCTION= 0x40     # Dec: 64 未实现功能

end