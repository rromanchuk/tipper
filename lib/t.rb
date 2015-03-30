$stdout.sync = true

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sqs
  sqs = Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def publish_new_tweet(user)
  apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 1 } }.to_json
  resp = sns.publish(
    target_arn: user["EndpointArn"],
    message_structure: "json",
    message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload }.to_json
  )
end

EventMachine.run {
  User.all.items.reverse.each do |user|
  puts "Starting stream for user #{user}"
  client = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = "***REMOVED***"
    config.consumer_secret     = "DCL7zOahnqqH7DLAy6VMlCn5ZH866Nwylb5YYmInuue6MR510I"
    config.access_token        = user["TwitterAuthToken"]
    config.access_token_secret = user["TwitterAuthSecret"]
  end

  EventMachine.defer {
    client.user(with: "user") do |object|
      case object
      when Twitter::Tweet
        puts "It's a tweet!"
      when Twitter::DirectMessage
        puts "It's a direct message!"
      when Twitter::Streaming::StallWarning
        puts "Falling behind!"
      when Twitter::Streaming::Event
        puts "Found a favorite event..."
        puts "Source #{object.source.id}, Target #{object.target.id}, object #{object.target_object.id}"
        publish_new_tweet(user)
        sqs.send_message(queue_url: SQSQueues.new_tip, message_body: { "TweetID": object.target_object.id, "FromTwitterID": object.target.id, "ToTwitterID":  object.source.id  }.to_json )
      end
    end
    }
end
}






