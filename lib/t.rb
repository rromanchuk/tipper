
client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = "ceq5QuL3OUCQAtfqAs7EjzlCA"
  config.consumer_secret     = "LZUKfMfwASOIXPODFevkjbcwqnSozbmO390V6c3QbcmKT5wI8L"
  config.access_token        = "14078827-l8rTyDKpEuawWdUnKgjQfcyxQdutQSN8bw9a549Xq"
  config.access_token_secret = "VQtQnuDJLjZsH6eGxbNdJXasyk3TgFnfAruTd6j2ukw8P"
end

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sqs
  sqs = Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def queue_favorite(from_user, to_user)
  resp = sqs.send_message(queue_url: "https://sqs.us-east-1.amazonaws.com/080383581145/TipperNewTip", 
    message_body: {from_user: from_user, to_user: to_user}.to_json )
end

client.user(with: "user") do |object|
  case object
  when Twitter::Tweet
    puts "It's a tweet!"
  when Twitter::DirectMessage
    puts "It's a direct message!"
  when Twitter::Streaming::StallWarning
    warn "Falling behind!"
  when Twitter::Streaming::Event
    puts object.inspect
    puts "Event"
    puts "Source #{object.source.inspect}, Target #{object.target.inspect}"
  end
end


def publish_new_tweet
  apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 14 } }.to_json
  resp = sns.publish(
    topic_arn: "arn:aws:sns:us-east-1:080383581145:NewTipperFavorite",
    message_structure: "json",
    message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload }.to_json
  )
  puts resp.inspect
end



publish_new_tweet
queue_favorite("432432", "24423")
