var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var marshal = require('dynamodb-marshaler');

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var txid = event.txid
    var readparams = {
      Key: {
        txid: {S: txid}
      },
      TableName: 'TipperBitcoinTransactions'
    };

    get(function(item) {
    	context.done(null, JSON.parse(item))
    });
    
    function get(cb) {
    	dynamodb.getItem(readparams, function(err, data) {
	        if (err) { return console.log(err); }
	        var item = marshal.unmarshalJson(data.Item)
	        cb(item);
        });    
    }
};