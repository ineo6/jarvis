const jenkins = require('jenkins');

const jenkinsObj = jenkins({
  baseUrl: process.env.HUBOT_JENKINS_URL,
  crumbIssuer: true
});

module.exports = function (robot) {

  function getJobs(jobs) {
    let result = [];

    jobs.forEach(job => {
      if (['org.jenkinsci.plugins.workflow.job.WorkflowJob', "hudson.model.FreeStyleProject"].indexOf(job._class) >= 0) {
        const state = job.color === "red" ? "FAIL" : job.color === "aborted" ? "ABORTED" : job.color === "aborted_anime" ? "CURRENTLY RUNNING" : job.color === "red_anime" ? "CURRENTLY RUNNING" : job.color === "blue_anime" ? "CURRENTLY RUNNING" : "PASS";
        result.push({
          text: "" + job.fullName + " " + state,
          value: job.fullName
        });
      } else if (job._class === 'com.cloudbees.hudson.plugins.folder.Folder') {
        result = result.concat(getJobs(job.jobs));
      }
    });

    return result;
  }

  robot.respond(/j(?:enkins)? build$/i, function (res) {

    return jenkinsObj.job.list({
      depth: 1,
      tree: "jobs[name,fullName,color,jobs[name,_class,fullName,color]]"
    }, function (err, data) {
      if (err) {
        res.send("error: " + err.message);
        return;
      }

      const jobs = getJobs(data);

      if (!jobs.length) {
        return res.send("no job exists.");
      } else {
        console.log(jobs);
        return res.send(jobs);
      }
    });
  });
  robot.respond(/j(?:enkins)? build ([\w\.\-_ ]+)(, (.+))?/i, function (res) {
    const job = res.match[1];

    return jenkinsObj.job.build(job, function (err, data) {
      if (err) {
        res.send("error: " + err.message);
        return;
      }
      return res.send("" + job + " job is started by " + res.message.user.name);
    });
  });
};
