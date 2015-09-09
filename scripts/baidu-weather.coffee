# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

ak = process.env.HUBOT_BAIDU_AK or '9c9aa117da8912d2c59cb2efd941edd6'

module.exports = (robot) ->
   
    robot.respond /([\u4e00-\u9fa5]+) 天气/, (msg) ->
      city = msg.match[1]
      robot.http('http://api.map.baidu.com/telematics/v3/weather?ak='+ak+'&location='+city+'&output=json')
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
          #console.log JSON.stringify result
          for idx,day of result
            response += "#{idx}:  #{day['date']} #{day['weather']} #{day['wind']} #{day['temperature']}"+'\n'
            response += day[type+'PictureUrl']+'\n'
          #console.log JSON.stringify response
          msg.send response

check_time = (timezone = 8) ->
  d = new Date() 
  localTime = d.getTime()
  localOffset = d.getTimezoneOffset() * 60000  

  utc = localTime + localOffset; #得到国际标准时间  

  calctime = utc + (3600000*timezone)
  nd = new Date(calctime);  
  if 6 <= nd.getHours() <= 18
    'day'
  else
    'night'