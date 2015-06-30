require "eventmachine"
require "tweetstream"
require "em-hiredis"

REDIS_URL = ENV["REDIS_URLEDIS"]

class FavoritesStream

  def self.all
    @all ||= {}
  end

  def self.add oauth_token, oauth_token_secret
    raise "duplicate oauth" if all[oauth_token]
    all[oauth_token] = FavoritesStream.new(oauth_token, oauth_token_secret)
  end

  def self.remove oauth_token
    if fs = all[oauth_token]
      fs.stop
      all.delete(oauth_token)
    else
      raise "stream not found for #{oauth_token}"
    end
  end

  def initialize oauth_token, oauth_token_secret
    @oauth_token = oauth_token
    @oauth_token_secret = oauth_token_secret
  end

  def client
    @client ||= TweetStream::Client.new(consumer_key: ENV["TWITTER_CONSUMER_KEY"],
                                        consumer_secret: ENV["TWITTER_CONSUMER_SECRET"],
                                        oauth_token: @oauth_token,
                                        oauth_token_secret: @oauth_token_secret)
  end

  def user
    @user ||= User.find_by_twitter_token(@oauth_token)
  end

  def self.sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def self.sqs
    FavoritesStream.sqs
  end

  def start
    client.on_event(:favorite) do |event|
      puts event.to_yaml

      EM.defer {
        # TODO Send stuff to sqs.
        if event.source.id_str == user["TwitterUserID"] && event.source.id_str != event.target.id_str
          publish_new_tweet(user)
          sqs.send_message(queue_url: SqsQueues.new_tip, message_body: { "TweetID": event.target_object.id_str, "FromTwitterID": event.source.id_str, "ToTwitterID": event.target.id_str }.to_json )
        else
          puts "Skipping..."
        end
      }
    end.userstream
  end

  def stop
    client.stop
  end
end

EM.run {

  User.find_active.items.each do |user|
    puts "Adding active user #{user["TwitterUsername"]}"
    FavoritesStream.add(user['TwitterAuthToken'], user['TwitterAuthSecret'])
  end

  FavoritesStream.all.each do |token, stream|
    stream.start
  end

  redis = EM::Hiredis.connect(REDIS_URL)

  puts "Subscribing to new users..."
  redis.pubsub.subscribe("new_users") { |msg|
    parsed = JSON.parse(msg)
    FavoritesStream.add(parsed['oauth_token'], parsed['oauth_token_secret'])
  }
}
