var https = require('https');

console.log('Loading function');

exports.handler = async (event, context) => {

    const subject = event.Records[0].Sns.Subject;
    const message = event.Records[0].Sns.Message;

    const postData = JSON.stringify({ text:"Subject: " + subject + "\nMessage: " + message});

    return new Promise((resolve, reject) => {
        const options = {
          method: 'POST',
          hostname: 'hooks.slack.com',
          port: 443,
          path: process.env.webhook,
          headers: {
            'Content-Type': 'application/json'
          }
        };

        const req = https.request(options, (res) => {
          resolve('Success');
        });

        req.on('error', (e) => {
          reject(e.message);
        });

        // send the request
        req.write(postData);
        req.end();
    });
};
