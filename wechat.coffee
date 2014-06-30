_ = require 'underscore'
xml2js = require 'xml2js'


wechat_middleware =
  get_body: (req, res, next) ->
    console.log 'request: ',  req
    req.rawBody = ''
    req.setEncoding('utf8')
    req.on 'data', (chunk) ->
      req.rawBody += chunk
    req.on 'end', ->
      next(req, res)


wechat_transport: (req, res, next) ->
  parser = new xml2js.Parser()
  parser.parseString req.rawBody, (error,result) ->
    return error if error    
    _.extend req,
      user_id: result.xml.FromUserName[0]
      developer_id: result.xml.ToUserName[0]
      type: result.xml.MsgType[0]
      content: result.xml.Content?[0]
      event: result.xml.Event?[0]
      key: result.xml.EventKey?[0]

    _.extend res,
      text: (content) ->
        @send "<xml>
          <ToUserName><![CDATA[#{req.user_id}]]></ToUserName>
          <FromUserName><![CDATA[#{req.developer_id}]]></FromUserName>
          <CreateTime>#{Date.now()}</CreateTime>
          <MsgType><![CDATA[text]]></MsgType>
          <Content><![CDATA[#{content}]]></Content>
          </xml>"
             
      article: ({title,description,url}) ->
        @send "<xml>
          <ToUserName><![CDATA[#{req.user_id}]]></ToUserName>
          <FromUserName><![CDATA[#{req.developer_id}]]></FromUserName>
          <CreateTime>#{new Date().getTime()}</CreateTime>
          <MsgType><![CDATA[news]]></MsgType>
          <ArticleCount>1</ArticleCount>
          <Articles>
          <item>
          <Title><![CDATA[#{title}]]></Title> 
          <Description><![CDATA[#{description}]]></Description>
          <Url><![CDATA[#{url}]]></Url>
          </item>
          </Articles>
          </xml>"
  next(req, res)



module.exports = class Wechat

  constructor: ({@appid, @appsecret}) ->
    @click_handlers = {}
    
    # superagent.get 'token', (err, @token) =>
      
    m = (req, res) =>
      wechat_middleware.get_body req, res, (req, res) =>
        wechat_middleware.transport req, res, (req, res) =>

          if req.type is 'text'
            @message_handler?(req,res)

          else if req.type is 'event'
            if req.event is 'subscribe'
              @subscribe_handler?(req, res)

            else if req.event is 'unsubscribe'
              @unsubscribe_handler?(req,res)
            
            else if req.event is 'CLICK'
              @click_handlers[req.key](req, res)


            else
              return  
          else
            return
          
    _.extend m,
      subscribe: (@subscribe_handler) =>

      click: (selector, handler) =>
        @click_handlers[selector] = handler

      unsubscribe: (@unsubscribe_handler) =>

      message: (@message_handler) =>

    return m
