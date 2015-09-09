# Description
#   查看知乎日报
#
# Configuration:
#	none
#
# Commands:
#   hubot zhihu today - 获取知乎日报今日全部消息
#   hubot zhihu latest <count> - 获取知乎日报最新消息
#   hubot zhihu before yyyymmdd - 获取知乎日报历史消息
#
# Notes:
#   none
#
# Author:
#   suosuopuo[suosuopuo@gmail.com]

module.exports = (robot) ->
  robot.respond /zhihu today/i, (msg) ->
    msg.http("http://news-at.zhihu.com/api/4/news/latest")
      .get() (err, res, body) ->
        if err
          msg.send "Sorry, something went wrong...╮（╯＿╰）╭"
          return
        process_stories_nopic msg, JSON.parse(body).stories

  robot.respond /zhihu latest (\d+)?/i, (msg) ->
    msg.http("http://news-at.zhihu.com/api/4/news/latest")
      .get() (err, res, body) ->
        if err
          msg.send "Sorry, something went wrong...╮（╯＿╰）╭"
          return
        count = msg.match[1] || 3
        process_stories msg, JSON.parse(body).stories, count

  robot.respond /zhihu before ([0-9]{8})/i, (msg) ->
    msg.http("http://news-at.zhihu.com/api/4/news/before/" + msg.match[1])
      .get() (err, res, body) ->
        if err
          msg.send "Sorry, something went wrong...╮（╯＿╰）╭"
          return
        process_stories_nopic msg, JSON.parse(body).stories

process_stories = (msg, stories, cnt) ->
  cnt = stories.length if cnt > stories.length
  for i in [0..cnt-1]
    story = stories[i]
    content = ''
    content += story.title + '\n'
    content += '原文: http://daily.zhihu.com/story/' + story.id + '\n'
    content += story.images[0] + '\n' if story.images? && story.images.length
    content += story.image + '\n' if story.image?
    content += '\n'
    msg.send content

process_stories_nopic = (msg, stories) ->
  content = ''
  for story in stories
    content += story.title + '\n'
    content += '原文: http://daily.zhihu.com/story/' + story.id + '\n'
    content += '\n'
  msg.send content
