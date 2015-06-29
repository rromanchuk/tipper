require "eventmachine"
require "tweetstream"
require "em-hiredis"

REDIS_URL = "redis://tipper.7z2sws.0001.use1.cache.amazonaws.com:6379/0"

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
    @client ||= TweetStream::Client.new(consumer_key: "***REMOVED***",
                                        consumer_secret: "***REMOVED***",
                                        oauth_token: @oauth_token,
                                        oauth_token_secret: @oauth_token_secret)
  end

  def start
    client.on_event(:favorite) do |event|
      puts event.to_h

      EM.defer {
        # TODO Send stuff to sqs.
      }
    end.userstream
  end

  def stop
    client.stop
  end
end

EM.run {
  redis = EM::Hiredis.connect(REDIS_URL)

  puts "Subscribing to new users..."
  redis.pubsub.subscribe("new_users") { |msg|
    parsed = JSON.parse(msg)
    FavoritesStream.add(parsed['oauth_token'], parsed['oauth_token_secret'])
  }
}
