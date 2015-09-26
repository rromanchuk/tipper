var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var marshal = require('dynamodb-marshaler');

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var txid = event.id
    var readparams = {
      Key: {
        txid: {S: txid}
      },
      TableName: 'TipperBitcoinTransactions'
    };

    get()
    
    function get() {
    	dynamodb.getItem(readparams, function(err, data) {
	        if (err) { return console.log(err); }
	        console.log(": " + data.Item);
	        var item = marshal.unmarshalJson(data.Item)
	        context.succeed(item);  // Echo back the first key value
        });    
    }
};