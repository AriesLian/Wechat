mongoose = require 'mongoose'


mongoose.connect('mongodb://localhost/cme')
wechat_ic_schema = new mongoose.Schema({
  user_id: String
  user_name: String
  ic_code: String
  confirmed: Boolean
  })

Wechat_ic = mongoose.model('Wechat_ic',wechat_ic_schema)
module.exports = Wechat_ic
