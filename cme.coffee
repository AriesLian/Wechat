Haoys = require './doctor'
User = require './schema'
Wechat = require './wechat'

# https://mp.weixin.qq.com/advanced/advanced?action=dev&t=advanced/dev&token=863512011&lang=zh_CN
# https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=APPID&secret=APPSECRET

module.exports = wechat = new Wechat
  appid: 'wx6d5dbadefa8181fc'
  secret: '0d29c584fd36154738386e133a22d9c3'

article = (req, ic_code, score) ->
  title: """#{score.year}年学分"""
  description: """

  总学时\t:\t#{score.total_time}
  总学分\t:\t#{score.total_score}
  Ⅰ类学分\t:\t#{score.level1}
  Ⅱ类学分\t:\t#{score.level2}

  """
  url: "#{req.protocol}://#{req.host}/cme/#{ic_code}/#{score.year}"

wechat.subscribe (req, res) ->
  User.findOne(user_id: req.user_id).exec (err, user) ->
    return res.send 500 if err
    res.text '感谢关注。请回复好医生学习IC卡号，与微信完成绑定，以用来查询学分。' if not user?

wechat.unsubscribe ({user_id}, res) ->

wechat.message (req, res) ->
  {user_id, content} = req
  User.findOne(user_id: user_id).exec (err, user) ->
    return res.send 500 if err
    if not user
      Haoys.find {ic_code: content}, (err, score) ->
        return res.send 500 if err
        return res.text '无此学习卡信息' if not score
        user = new User
          user_id   : user_id
          user_name : score.name
          ic_code   : content
        user.save (err, user) ->
          return res.send 500 if err
          res.text "好医生个人IC卡号验证成功，IC卡用户为“#{score.name}”，回复“是”完成绑定。"
    else if not user.confirmed
      if content is '是'
        user.confirmed = on
        user.save (err, user) ->
          return res.send 500 if err
          Haoys.find {ic_code: user.ic_code}, (err, score) ->
            return res.send 500 if err
            res.article article req, user.ic_code, score
      else
        res.text "已提交好医生个人IC卡号绑定申请，好医生个人IC卡用户为#{user.user_name}，回复“是”完成绑定。"
    else
      Haoys.find {ic_code: user.ic_code, year: content}, (err, score) ->
        return res.send 500 if err
        return res.text "#{content}年无学分" unless score?
        res.article article req, user.ic_code, score

wechat.click 'GET_SCORE', (req, res) ->
  {user_id} = req
  User.findOne(user_id: user_id).exec (err, user) ->
    return res.send 500 if err
    return res.text '您的微信未绑定好医生IC卡号，回复“好医生学习IC卡号”，与微信号绑定；绑定成功后查询学分无需再次输入IC卡号。' unless user
    return res.text "已提交好医生个人IC卡号绑定申请,好医生个人IC卡用户为“#{user.user_name}”,回复“是”完成绑定。" unless user.confirmed
    Haoys.find {ic_code: user.ic_code}, (err, score) ->
      return res.send 500 if err
      res.article article req, user.ic_code, score
