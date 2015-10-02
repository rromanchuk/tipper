var https = require('https');
var AWS = require('aws-sdk');
var dynamodb = new AWS.DynamoDB();
var docClient = new AWS.DynamoDB.DocumentClient();


exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var txid = event.txid
    var readparams = {
      Key: {
        txid: txid
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
        console.log(tx)
        docClient.update({  
            "TableName" : "TipperBitcoinTransactions",
            "Key" : {
                "txid" :  tx["hash"]
            },
            "ReturnValues": "ALL_NEW",
            "UpdateExpression" : "SET #confirmations = :confirmations, #inputs = :inputs, #outputs = :outputs",
            "ExpressionAttributeNames" : {"#confirmations" : "confirmations", "#inputs": "inputs", "#outputs": "outputs"},
            "ExpressionAttributeValues" : {
                ":confirmations" : tx["confirmations"].toString(),
                ":inputs" : tx["inputs"],
                ":outputs" : tx["outputs"]
            }
        }, function(err, data){
            if (err) console.log(err, err.stack); // an error occurred
            console.log(JSON.stringify(data.Attributes));
            docClient.get(readparams, function(err, data) {
                if (err) { return console.log(err); }
                context.done(null, data.Item)
            });             
        });
    }
};