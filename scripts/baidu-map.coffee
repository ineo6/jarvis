# Description
#   baidu map,百度地图
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   ineo6 <arklove@qq.com>

ak = process.env.HUBOT_BAIDU_AK or '9c9aa117da8912d2c59cb2efd941edd6'

SUGGESTION_API = 'http://api.map.baidu.com/place/v2/suggestion'
DIRECTION_API = 'http://api.map.baidu.com/direction/v1'
GEOCODING_API = 'http://api.map.baidu.com/geocoder/v2'
POINT_API = 'http://api.map.baidu.com/telematics/v3/point'
TRAVEL_ATTRACTIONS_API = 'http://api.map.baidu.com/telematics/v3/travel_attractions'  # noqa
TRAVEL_CITY_API = 'http://api.map.baidu.com/telematics/v3/travel_city'
LOCAL_API = 'http://api.map.baidu.com/telematics/v3/local'
WEATHER_API = 'http://api.map.baidu.com/telematics/v3/weather'

DIRECTION = 0
NODIRECTION = 1
NOSCHEME = 2

module.exports = (robot) ->
  robot.respond /从([\u4e00-\u9fa5_a-zA-Z0-9]+)[\u53bb|\u5230]([\u4e00-\u9fa5_a-zA-Z0-9]+)([\s\u4e00-\u9fa5_a-zA-Z0-9]+|$)/, (res) ->
    origin = res.match[1]
    dest = res.match[2]

    if not res.match[3]?
      mode = 'transit'
    else if res.match[3].trim() == '开车'
      mode = 'driving'
    else if res.match[3].trim() == '步行'
      mode = 'walking'

    place_direction res,origin,dest,mode,(ret)->
      if ret[0] == NOSCHEME
        text= ['输入的太模糊了, 你要找得起点可以选择:',
        ret[1].join('|'),'终点可以选择:',ret[2].join('|')].join('\n')
      else if ret[0] == NODIRECTION
        reg = ''
        if ret[1]
          reg += '起点'
        if ret[2]
          reg += '终点'
        #console.log JSON.stringify ret
        text = '输入的'+reg+'太模糊了: 以下是参考:'+'\n'+ ret[1].join('\n')+ret[2].join('\n')
      else 
        _result= ret[1].join('\n')
        if mode= 'driving'
          text= '最优路线: '+_result+' \n['+ret[2]+']'
        else
          text= '最优路线: '+_result+' '+ret[2]
      res.send text

#
place_direction = (msg,origin, destination, mode='transit',callback, tactics=11,region='上海', origin_region='上海',destination_region='上海') ->
  params  =
    origin:       origin
    destination:  destination
    ak:           ak
    output:      'json' 
    mode:        mode
    tactics:     tactics

  if mode != 'transit'
    params['origin_region']=origin_region
    params['destination_region']=destination_region
  else
    params['region']=region

  msg.http(DIRECTION_API)
    .query(params)
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      # error checking code here
      data = JSON.parse body
      if err or data.status !=0
        msg.send "Sorry, something went wrong...╮（╯＿╰）╭"
        return
      result= data['result']
      #console.log JSON.stringify data
      if data['type'] == 1
        if !result
          place_suggestion res,origin,(oResult)->
            place_suggestion res,destination,(dResult)->
              return [NOSCHEME,oResult,dResult]

        if mode != 'transit'
          _origin = result['origin']['content']
          _dest = result['destination']['content']
        else
          _origin = result['origin']
          _dest = result['destination']
        if _origin
          #console.log JSON.stringify _origin
          o = for tmpO in _origin
            tmpO['name']+': '+ tmpO['address']
        else
          o= []
        if _dest
          d= for tmpO of _dest
            _dest[tmpO]['name']+': '+ _dest[tmpO]['address']
        else
          d= []
        return callback [NODIRECTION,o,d]
      if mode == 'driving'
        taxi = result['taxi']
        for d in taxi['detail']
          if d['desc'].indexOf('白天')>=0
            daytime = d
          else:
            night = d
        is_daytime = 5 < new Date().getHours() < 23
        if is_daytime
          price = daytime['total_price'] 
        else 
          price = night['total_price']
        remark = taxi['remark']
        taxi_text = remark+' 预计打车费用 '+price+'元'
        steps = result['routes'][0]['steps']
        setps_str=for k,s of steps
          s['instructions'].replace(/<[^>]+>/g, '')
        callback [DIRECTION, setps_str, taxi_text]
      else if mode=='walking'
        steps = result['routes'][0]['steps']
        setps_str= for k,s of steps
          s['instructions'].replace(/<[^>]+>/g, '')
        callback [DIRECTION,   setps_str, '']
      else
        #console.log JSON.stringify data
        schemes = result['routes']
        steps = []
        for index,scheme of schemes
          scheme = scheme['scheme'][0]
          step = '*方案'+index+' [距离: '+scheme['distance'] / 1000+'公里, 花费: '+scheme['price'] / 100+'元, 耗时: '+scheme['duration'] / 60+'分钟]:\n'

          stepsList= for k,s of scheme['steps']
            s[0]['stepInstruction'].replace(/<[^>]+>/g, '')
          step += stepsList.join('\n')

          step += '\n' + Array(40).join('-')
          steps[steps.length]=step
        callback [DIRECTION,steps, '']

place_suggestion = (msg,pos,callback)->
  params =
    query:  pos 
    region: '上海'
    ak:     ak
    output: 'json'

  msg.http(SUGGESTION_API)
    .query(params)
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      data = JSON.parse body
      if err or data.status != 0
        msg.send "Sorry, something went wrong...╮（╯＿╰）╭"
        return
      callback([r['name'] for r in data['result']])