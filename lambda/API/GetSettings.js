var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var versionId = event.versionId
    var readparams = {
      Key: {
        Version: versionId
      },
      TableName: 'TipperSettings'
    };
        
	docClient.get(readparams, function(err, data) {
        if (err) { return console.log(err); }
        context.done(null, data.Item)
    });    
};