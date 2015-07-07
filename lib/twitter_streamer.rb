require "bundler/setup"

require "dotenv"
Dotenv.load

require "pp"

require "eventmachine"
require "tweetstream"
require "em-hiredis"
require "aws-sdk"

require_relative "./sqs_queues"
require_relative "../app/models/user"

class FavoritesStream
  def self.all
    @all ||= {}
  end

  def self.add oauth_token, oauth_token_secret
    if all.has_key?(oauth_token)
      Rails.logger.info "already have #{oauth_token}, not adding"
    else
      all[oauth_token] = FavoritesStream.new(oauth_token, oauth_token_secret)
      all[oauth_token].start
    end
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

  def start
    client.on_event(:favorite) do |event|
      publish(event)
    end.userstream
  end

  def publish event
    EM.defer {
      pp event
      if valid_event? event
        message = {queue_url: SqsQueues.new_tip, message_body: { "TweetID": event[:target_object][:id_str], "FromTwitterID": event[:source][:id_str], "ToTwitterID": event[:target][:id_str] }.to_json }
        Rails.logger.info "message to sqs: #{message}"
        self.class.sqs.send_message(message)
      else
        Rails.logger.error "invalid event, skipping"
      end
    }
  end

  def valid_event? event
    object.source.id.to_s == user["TwitterUserID"] && object.source.id.to_s != object.target.id.to_s
  end

  def stop
    client.stop
  end
end

active_users = User.find_active.items

EM.run {
  # Add existing users.
  # TODO On larger sets of users use EM::Iterator.
  active_users.each do |user|
    if user['TwitterAuthToken'] && user['TwitterAuthSecret']
      Rails.logger.info "Adding: #{user["TwitterUsername"]}"
      FavoritesStream.add user['TwitterAuthToken'], user['TwitterAuthSecret']
    else
      Rails.logger.info "Skipping (no valid oauth in db): #{user["TwitterUsername"]}"
    end
  end

  # Subscribe to new users.
  Rails.logger.info "Subscribing to new users"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])
  redis.pubsub.subscribe("new_users") { |msg|
    parsed = JSON.parse(msg)
    FavoritesStream.add(parsed['oauth_token'], parsed['oauth_token_secret'])
  }
}
