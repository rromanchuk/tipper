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
  puts resp.inspect
end

EventMachine.run {
  User.all.items.reverse.each do |user|
  puts "Starting stream for user #{user}"
  client = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = "O3S9j8D3ZJQZCU6DcI1ABjinR"
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
        puts object.inspect
        puts "Event"
        puts "Source #{object.source.inspect}, Target #{object.target.inspect}"
        publish_new_tweet
        sqs.send_message(queue_url: SQSQueues.new_tip, message_body: { "TweetID": object.target_object.id, "FromTwitterID": object.source.id, "ToTwitterID": object.target.id }.to_json )
      end
    end
    }
end
}






