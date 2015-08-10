

console.log('Loading function');
var aws = require('aws-sdk');
var doc = require('dynamodb-doc');
var async = require('async');
var dynamodb = new doc.DynamoDB();


var sqs = new aws.SQS();
var Twitter = require('twitter');



exports.handler = function(event, context) {
  console.log('Received event:', JSON.stringify(event, null, 2));
  var token = event.token;
  var secret = event.secret;
  var userId = event.userId;
  var twitterId = event.twitterId;
  var consumerKey = event.consumer_key;
  var consumerSecret = event.consumer_secret;
  var sinceId = event.since_id;

  var client = new Twitter({
    consumer_key: consumerKey,
    consumer_secret: consumerSecret,
    access_token_key: token,
    access_token_secret: secret
  });


  client.get('favorites/list', {"user_id": twitterId, "count": 200, "since_id": sinceId}, function(error, tweets, response) {
		console.log("Number of tweets ----->" + tweets.length);
    if(error) {
      console.log(error);
      context.fail('Favorites fetch failed');
    } else {
      async.eachSeries(tweets, function iterator(item, callback) {
        var params = {};
        var hashRangeKey = {"ObjectID": item["id_str"], "FromUserID": userId};
        console.log("Found favorites " + item["text"]);
        console.log("Looking for up tip from dynamo");
        console.log(hashRangeKey);
        params.TableName = "TipperTips";
        params.Key = hashRangeKey;

        dynamodb.getItem(params, function(err, data) {
          if (err) {
              console.log(err, err.stack); // an error occurred
              context.fail('dynamodb.getItem failed');
          } else {
              if (data.length > 0) {
                  console.log("Tip already exists...")
              } else {
                  console.log("New tip found... ")
                  var message = { "TweetID": item["id_str"], "FromTwitterID": twitterId, "ToTwitterID": item["user"]["id_str"] };
                  console.log("About to send sqs");
                  console.log(message);
                  var params = {"QueueUrl": "***REMOVED***", "MessageBody": JSON.stringify(message) };
                  //sqs.sendMessage(params, function(err, data) {
                  //    if (err) console.log(err, err.stack); // an error occurred
                  //    else     console.log(data);           // successful response
                  //});
              }
              callback(null, item);  // Echo back the first key value
          }
        });
      }, function done() {
        //...
        console.log("Async finished")
        context.succeed();
      });

    }
 });

        
    
    
    
};