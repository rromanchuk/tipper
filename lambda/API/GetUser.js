
var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var userId = event.userId
    var readparams = {
      Key: {
        UserID: userId
      },
      TableName: 'TipperUsers'
    };
        
	docClient.get(readparams, function(err, data) {
        if (err) { return console.log(err); }
        context.done(null, data.Item)
    });    
};