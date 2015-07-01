require "bundler/setup"

require "dotenv"
Dotenv.load

require "pp"

require "eventmachine"
require "tweetstream"
require "em-hiredis"
require "aws-sdk"

require_relative "./sqs_queues"

class FavoritesStream
  def self.all
    @all ||= {}
  end

  def self.add oauth_token, oauth_token_secret
    raise "duplicate oauth" if all[oauth_token]
    all[oauth_token] = FavoritesStream.new(oauth_token, oauth_token_secret)
    all[oauth_token].start
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

  def self.sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def start
    client.on_event(:favorite) do |event|
      publish(event)
    end.userstream
  end

  def publish event
    EM.defer {
      pp event
      if valid_event? event
        self.class.sqs.send_message(queue_url: SqsQueues.new_tip, message_body: { "TweetID": event[:target_object][:id_str], "FromTwitterID": event[:source][:id_str], "ToTwitterID": event[:target][:id_str] }.to_json )
      else
        puts "invalid event, skipping"
      end
    }
  end

  def valid_event? event
    event[:source][:id] != event[:target][:id]
  end

  def stop
    client.stop
  end
end

EM.run {

  # User.find_active.items.each do |user|
  #   puts "Adding active user #{user["TwitterUsername"]}"
  #   FavoritesStream.add(user['TwitterAuthToken'], user['TwitterAuthSecret'])
  # end

  # FavoritesStream.all.each do |token, stream|
  #   stream.start
  # end

  puts "Subscribing to new users..."
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])
  redis.pubsub.subscribe("new_users") { |msg|
    parsed = JSON.parse(msg)
    FavoritesStream.add(parsed['oauth_token'], parsed['oauth_token_secret'])
  }
}
