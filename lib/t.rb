require 'twitter'
client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = "***REMOVED***"
  config.consumer_secret     = "LZUKfMfwASOIXPODFevkjbcwqnSozbmO390V6c3QbcmKT5wI8L"
  config.access_token        = "***REMOVED***"
  config.access_token_secret = "***REMOVED***"
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

resp = dynamodb.put_item(
  # required
  table_name: "TableName",
  # required
  item: {
    "AttributeName" => "value", #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
  }
)