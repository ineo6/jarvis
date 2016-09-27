# Description
#   查询天气
#
# Configuration:
#	none
#
# Commands:
#   hubot 上海天气 - 获取天气
#
# Notes:
#   none
#
# Author:
#   ineo6 <arklove@qq.com>

ak = process.env.HUBOT_BAIDU_AK or '9c9aa117da8912d2c59cb2efd941edd6'
room = process.env.HUBOT_SLACK_EVENT_ROOM or 'Shell'

module.exports = (robot) ->
#todo 提取出明日天气,关键字过滤.封装成 on 里面的方法.
  robot.respond /([\u4e00-\u9fa5]+)天气/, (msg) ->
    city = msg.match[1]
    robot.http('http://api.map.baidu.com/telematics/v3/weather?ak=' + ak + '&location=' + city + '&output=json')
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      jsonBody = JSON.parse body
      if err or jsonBody.error != 0
        console.log JSON.stringify err
        msg.reply "Weather Something Wrong !"
        return
      response = ''
      result = jsonBody['results'][0]['weather_data']

      type = check_time 8
      for idx,day of result
        response += "#{idx}:  #{day['date']} #{day['temperature']} #{day['weather']} #{day['wind']} #{day['temperature']}" + '\n'
        response += day[type + 'PictureUrl'] + '\n'
      msg.send response

  robot.on "baidu_weather", (params) ->
    robot.http('http://api.map.baidu.com/telematics/v3/weather?ak=' + ak + '&location=' + params.city + '&output=json')
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      jsonBody = JSON.parse body
      if err or jsonBody.error != 0
        console.log JSON.stringify err
        robot.reply "Weather Something Wrong !"
        return
      response = ''
      result = jsonBody['results'][0]['weather_data']

      type = check_time 8
      #console.log JSON.stringify result
      response += "明天(#{result[1]['date']}) #{result[1]['temperature']} #{result[1]['weather']} #{result[1]['wind']} #{result[1]['temperature']}" + '\n'
      response += result[1][type + 'PictureUrl'] + '\n'

      robot.messageRoom room, response

check_time = (timezone = 8) ->
  d = new Date()
  localTime = d.getTime()
  localOffset = d.getTimezoneOffset() * 60000

  utc = localTime + localOffset; #得到国际标准时间

  calctime = utc + (3600000 * timezone)
  nd = new Date(calctime);
  if 6 <= nd.getHours() <= 18
    'day'
  else
    'night'
