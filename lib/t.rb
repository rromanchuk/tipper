$stdout.sync = true

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sqs
  sqs = Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def publish_new_tweet(user)
  return unless user["EndpointArn"]

  begin
    apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 1 } }.to_json
    resp = sns.publish(
      target_arn: user["EndpointArn"],
      message_structure: "json",
      message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload }.to_json
    )
  rescue Aws::SNS::Errors::EndpointDisabled
    puts "Aws::SNS::Errors::EndpointDisabled"
  end
end

EventMachine.run {
  User.all.items.reverse.each do |user|
    next unless user["IsActive"] == "X"
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
        puts "Found event: #{object.name}"
        puts "name: #{object.name}, currentUser: #{user["TwitterUserID"]},  Source #{object.source.id}, Target #{object.target.id}, object #{object.target_object.id}"
        if object.name == :favorite
          if object.source.id.to_s == user["TwitterUserID"]
            publish_new_tweet(user)
            sqs.send_message(queue_url: SQSQueues.new_tip, message_body: { "TweetID": object.target_object.id.to_s, "FromTwitterID": object.source.id.to_s, "ToTwitterID": object.target.id.to_s }.to_json )
          else
            puts "Skipping..."
          end
        end
      end
    end
    }
end
}






