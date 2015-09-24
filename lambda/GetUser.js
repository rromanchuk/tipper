console.log('Loading function');
var http = require('http');
var https = require('https');
var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var marshal = require('dynamodb-marshaler');

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    https.get({
        host: 'bitcoin.toshi.io',
        path: '/api/v0/transactions/b6f6991d03df0e2e04dafffcd6bc418aac66049e2cd74b80f14ac86db1e3f0da'
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
            var item = marshal.unmarshal(data["Attributes"]);
            context.succeed(JSON.stringify(item));  // Echo back the first key value
        });
    }
};