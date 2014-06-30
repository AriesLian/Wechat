#requir
superagent = require 'superagent'
#要npm install 低版本的Jquery,能解析dom
$ = require('jquery')
moment = require 'moment'

keys = ['name','date','project_name','level','subject','type','time','score']
MIN_START_DATE = "2000"

exports.find = find = ({ic_code,year},callback) ->
  start = ""
  end = ""
  ic_code = ic_code.toUpperCase()
  flag = year?
  if flag
    return callback('你输入的年份格式不正确') unless /^\d{4}$/.test year
    return callback("请输入在#{MIN_START_DATE}-#{moment().year()}年间的年份") if year >moment().year() or year < MIN_START_DATE
  if flag and moment(year).year() is moment().year()
    #假如是今年
    start = moment(year).format('YYYY-MM-DD')
    end   = moment().format('YYYY-MM-DD')
  else
    start = moment(year).format('YYYY-MM-DD')
    end = "#{moment(year).year()}-12-31"
  console.log "-----------------"
  
  #递归查询好医生网站数据
  query_data {ic_code:ic_code,start_date:start,end_date:end,flag:flag},callback
    

#查询数据函数
query_data = ({ic_code,start_date,end_date,flag},callback) ->
  
  console.log start_date
  superagent.post('http://ic.haoyisheng.com/search/score_search.do')
  .type('form')
  .send("link=search")
  .send("icCode=#{ic_code}")
  .send("beginDateStr=#{start_date}")
  .send("endDateStr=#{end_date}")
  .on('error',-> return callback('请求错误'))
  .end (res)->

    $content = $(res.text)

    #四种情况停止递归(1,日期小于等于最早日期，2,传入了查询日期，3，查询到此编号不存在，4，查询到了数据)
    if moment(start_date).year() <= MIN_START_DATE or flag or not $content.find('#scoreInfoTable').length or  $content.find('#scoreInfoTable tr').length
      if $content.find("#scoreInfoTable tr").length
        doctor =
          year : moment(start_date).year().toString()
          scores: []
        score_infos = $content.find('#styleTypeInfo').text().match /\d+(.\d+)?/g
        doctor['total_time'] = score_infos[0]
        doctor['total_score'] = score_infos[1]
        doctor['level2'] = score_infos[2]
        doctor['level1'] = score_infos[3]
        #详细数据总列数
        tds = $content.find('#scoreInfoTable td').toArray()
        tds.forEach (td,index) ->
          doctor['name'] = td.innerHTML.trim() if index is 0
          if index%8 is 0
            doctor.scores.push {name:td.innerHTML.trim()}
          else if index%8 is 1
            doctor.scores[doctor.scores.length-1]['date'] = moment(td.innerHTML.trim()).format('M月D日')
          else
            doctor.scores[doctor.scores.length-1][keys[index%8]] = td.innerHTML.trim()
        callback null,doctor

      else
        callback null
    else
      query_data {ic_code:ic_code,start_date:"#{moment(start_date).year()-1}-01-01",end_date:"#{moment(start_date).year()-1}-12-31"},callback

#find {ic_code:'1106300U4',start_date:'2018'},(error,data) ->
# return console.log error if error
#  console.log data
