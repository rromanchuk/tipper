
var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var tipId = event.tipId
    var fromUserId = event.fromUserId
    var readparams = {
      Key: {
        ObjectID: tipId, 
        FromUserID: fromUserId
      },
      TableName: 'TipperTips'
    };
        
	docClient.get(readparams, function(err, data) {
        if (err) { return console.log(err); }
        context.done(null, data.Item)
    });    
};