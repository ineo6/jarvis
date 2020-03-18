'use strict';

// Description:
//   gitlab hooks
//
// Configuration:
//   None
//
// Commands:
//   None

const { Markdown, Text, ActionCard } = require('hubot-dingtalk/src/template');

const mockPush = require('../pushEvent');

// gitlab Webhooks
const requestToken = process.env.HUBOT_GITLAB_HOOK_TOKEN;


const HUBOT_JENKINS_COLOR_ABORTED = process.env.HUBOT_JENKINS_COLOR_ABORTED || "warning";
const HUBOT_JENKINS_COLOR_FAILURE = process.env.HUBOT_JENKINS_COLOR_FAILURE || "danger";
const HUBOT_JENKINS_COLOR_FIXED = process.env.HUBOT_JENKINS_COLOR_FIXED || "#d5f5dc";
const HUBOT_JENKINS_COLOR_STILL_FAILING = process.env.HUBOT_JENKINS_COLOR_STILL_FAILING || "danger";
const HUBOT_JENKINS_COLOR_SUCCESS = process.env.HUBOT_JENKINS_COLOR_SUCCESS || "good";
const HUBOT_JENKINS_COLOR_DEFAULT = process.env.HUBOT_JENKINS_COLOR_DEFAULT || "#ffe094";

module.exports = function (robot) {
  robot.router.post('/gitlab/web-hooks', (request, response) => {
    let data = {};

    if (request.body.payload) {
      JSON.parse(data = request.body.payload)
    } else {
      data = request.body
    }

    const token = request.get('X-Gitlab-Token');

    if (requestToken === token) {
      robot.logger.debug(`gitlab receive data ${JSON.stringify(data)}`);

      robot.messageRoom("", dispatchEvent(data));

      response.send('ok');
    } else {
      response.send("who are you!!!");
    }
  });

  function dispatchEvent(body) {
    let result = "";
    switch (body.object_kind) {
      case "push":
        result = pushEvent(body);
        break;
      case "tag":
        break;
    }

    console.log(JSON.stringify(result));

    return result;
  }

  function pushEvent(requestBody) {
    const { user_name, ref, object_kind, repository, commits } = requestBody;
    let branch = ref;
    branch = branch.slice(branch.lastIndexOf("/") + 1);

    const actionCard = new ActionCard();

    let title = `${user_name} pushed to branch ${branch} at repository ${repository.name}`,
      content = [`#### ${title}`];

    actionCard.setTitle(title);

    commits.forEach(commit => {
      content.push(`> ###### [${commit.id.substring(0, 8)}](${commit.url}): ${commit.message.replace('\n', '')}`);
    });

    actionCard.setContent(content.join('\n')).setBtns({
      title: "构建",
      actionURL: `dtmd://dingtalkclient/sendMessage?content=jenkins build ${branch}`
    });

    return actionCard.get();
  }

  robot.hear(/PING$/i, msg => {
    msg.send(dispatchEvent(mockPush))
  });

  robot.respond(/ADAPTER$/i, msg => {
    msg.send(robot.adapterName)
  });

  robot.respond(/ECHO (.*)$/i, msg => {
    msg.send(msg.match[1])
  });

  robot.respond(/TIME$/i, msg => {
    msg.send(`Server time is: ${new Date()}`)
  })

  return robot.router.post("/gitlab/jenkins", function (req, res) {
    let attachment, color, status;
    const room = req.query.room || "all";

    if (req.query.debug) {
      console.log(req.body);
    }

    const data = req.body;
    res.status(202).end();

    if (data.build.phase === "QUEUED") {
      return;
    }
    if (data.build.phase === "COMPLETED") {
      return;
    }

    attachment = {
      fields: []
    };
    attachment.fields.push({
      title: "Phase",
      value: data.build.phase,
      short: true
    });
    switch (data.build.phase) {
      case "FINALIZED":
        status = "" + data.build.phase + " with " + data.build.status;
        attachment.fields.push({
          title: "Status",
          value: data.build.status,
          short: true
        });
        color = (function () {
          switch (data.build.status) {
            case "ABORTED":
              return HUBOT_JENKINS_COLOR_ABORTED;
            case "FAILURE":
              return HUBOT_JENKINS_COLOR_FAILURE;
            case "FIXED":
              return HUBOT_JENKINS_COLOR_FIXED;
            case "STILL FAILING":
              return HUBOT_JENKINS_COLOR_STILL_FAILING;
            case "SUCCESS":
              return HUBOT_JENKINS_COLOR_SUCCESS;
            default:
              return HUBOT_JENKINS_COLOR_DEFAULT;
          }
        })();
        break;
      case "STARTED":
        status = data.build.phase;
        color = "#e9f1ea";
        attachment.fields.push({
          title: "Build #",
          value: "<" + data.build.full_url + "|" + data.build.number + ">",
          short: true
        });
        const params = data.build.parameters;
        if (params && params.ghprbPullId) {
          attachment.fields.push({
            title: "Source branch",
            value: params.ghprbSourceBranch,
            short: true
          });
          attachment.fields.push({
            title: "Target branch",
            value: params.ghprbTargetBranch,
            short: true
          });
          attachment.fields.push({
            title: "Pull request",
            value: "" + params.ghprbPullId + ": " + params.ghprbPullTitle,
            short: true
          });
          attachment.fields.push({
            title: "URL",
            value: params.ghprbPullLink,
            short: true
          });
        } else if (data.build.scm.commit) {
          attachment.fields.push({
            title: "Commit SHA1",
            value: data.build.scm.commit,
            short: true
          });
          attachment.fields.push({
            title: "Branch",
            value: data.build.scm.branch,
            short: true
          });
        }
    }
    attachment.color = color;
    attachment.pretext = "Jenkins " + data.name + " " + status + " " + data.build.full_url;
    attachment.fallback = attachment.pretext;
    if (req.query.debug) {
      console.log(attachment);
    }
    return robot.messageRoom("#" + room, {
      attachments: [attachment]
    });
  });
};
