console.log('Loading function');
var http = require('http');
var https = require('https');
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
    
    https.get({
        host: 'bitcoin.toshi.io',
        path: '/api/v0/transactions/' + txid
    }, function(response) {
        // Continuously update stream with data
        var body = '';
        response.on('data', function(d) {
            body += d;
        });
        response.on('end', function() {
            console.log(body);
            // Data reception is done, do whatever with it!
            var parsed = JSON.parse(body);
            console.log(parsed);
            updateTransaction(parsed)
        });
    });
    
    function updateTransaction(tx) {
        dynamodb.updateItem({  
            "TableName" : "TipperBitcoinTransactions",
            "Key" : {
                "txid" : { "S" : tx["hash"]}
            },
            "ReturnValues": "ALL_NEW",
            "UpdateExpression" : "SET #confirmations =:confirmations",
            "ExpressionAttributeNames" : {"#confirmations" : "confirmations"},
            "ExpressionAttributeValues" : {
            ":confirmations" : {
                "N" : tx["confirmations"].toString()
                }
            }
        }, function(err, data){
            if (err) console.log(err, err.stack); // an error occurred
            else     console.log(JSON.stringify(data));           // successful response
            console.log(JSON.stringify(data.Attributes));
            dynamodb.getItem(readparams, function(err, data) {
                if (err) { return console.log(err); }
                console.log(": " + data.Item);
                var item = marshal.unmarshalJson(data.Item)
                context.succeed(item);  // Echo back the first key value
            });             
        });
    }
};