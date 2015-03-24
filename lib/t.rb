

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sqs
  sqs = Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def queue_favorite(from_user, to_user)
  resp = sqs.send_message(queue_url: "***REMOVED***", 
    message_body: {from_user: from_user, to_user: to_user}.to_json )
end

def tip(from, to)
  if User.find(to)

  else

  end
end 




User.all.items.each do |user|
  puts "Starting stream for user #{user}"
  client = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = "***REMOVED***"
    config.consumer_secret     = "DCL7zOahnqqH7DLAy6VMlCn5ZH866Nwylb5YYmInuue6MR510I"
    config.access_token        = user["TwitterAuthToken"]
    config.access_token_secret = user["TwitterAuthSecret"]
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
      publish_new_tweet
      queue_favorite(object.source.id, object.target.id)
    end
  end
end



def publish_new_tweet
  apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 1 } }.to_json
  resp = sns.publish(
    topic_arn: "arn:aws:sns:us-east-1:080383581145:NewTipperFavorite",
    message_structure: "json",
    message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload }.to_json
  )
  puts resp.inspect
end



publish_new_tweet
queue_favorite("432432", "24423")

class TwitterFavorites

  def initialize
    puts "-------"
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "***REMOVED***"
      config.consumer_secret     = "DCL7zOahnqqH7DLAy6VMlCn5ZH866Nwylb5YYmInuue6MR510I"
    end
    @client = client

    def client.get_all_favorites
      collect_with_max_id do |max_id|
        options = {count: 200}
        options[:max_id] = max_id unless max_id.nil?
        favorites(options)
      end
    end
  end

  def client
    @client
  end

  def self.start
    User.all.items.each do |user|
      f = TwitterFavorites.new
      f.client.access_token        = user["TwitterAuthToken"]
      f.client.access_token_secret = user["TwitterAuthSecret"]
      favorites = f.client.get_all_favorites
      favorites.each_slice(25).each do |chunkedFavorites|
        Favorite.batchWrite(chunkedFavorites, user["TwitterUserID"])
      end
      favorites
    end
  end

  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    puts response.inspect
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end
end
