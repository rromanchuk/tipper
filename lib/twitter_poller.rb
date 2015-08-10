require "bundler/setup"

require "dotenv"
Dotenv.load

require "pp"

require "eventmachine"
require "em-hiredis"
require "aws-sdk"

require_relative "./sqs_queues"
require_relative "../app/models/user"

class FavoritesPoller
  def self.all
    @all ||= {}
  end

  def self.add oauth_token, oauth_token_secret
    if all.has_key?(oauth_token)
      Rails.logger.info "already have #{oauth_token}, not adding"
    else
      all[oauth_token] = FavoritesPoller.new(oauth_token, oauth_token_secret)
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
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = @oauth_token
      config.access_token_secret = @oauth_token_secret
    end
  end

  def user
    @user ||= User.find_by_twitter_token(@oauth_token)
  end

  def self.sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def self.lambda
    @lambda ||= Aws::Lambda::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def start
    EM.add_periodic_timer(25.0) do
      Rails.logger.info "About to invoke lambda for #{user["TwitterUsername"]}"
      publish
    end
  end

  def publish
    FavoritesPoller.lambda.invoke({
      function_name: "PollUserFavorites", # required
      invocation_type: "Event", # accepts Event, RequestResponse, DryRun
      payload: {consumer_key: ENV["TWITTER_CONSUMER_KEY"], consumer_secret: ENV["TWITTER_CONSUMER_SECRET"], token: @oauth_token, secret: @oauth_token_secret, userId: user["UserID"], twitterId: user["TwitterUserID"]}.to_json,
    })
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
      FavoritesPoller.add user['TwitterAuthToken'], user['TwitterAuthSecret']
    else
      Rails.logger.info "Skipping (no valid oauth in db): #{user["TwitterUsername"]}"
      NotifyUser.auth_token_expired(user)
    end
  end

  # Subscribe to new users.
  Rails.logger.info "Subscribing to new users"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])
  redis.pubsub.subscribe("new_users") { |msg|
    Rails.logger.info "Found new user: #{msg}"
    parsed = JSON.parse(msg)
    Rails.logger.info "Parsed redis message: #{parsed}"
    FavoritesPoller.add(parsed['oauth_token'], parsed['oauth_token_secret'])
  }

  Rails.logger.info "Subscribing to user diconnect events"
  redis.pubsub.subscribe("disconnect_user") { |msg|
    Rails.logger.info "Disconnecting user: #{msg}"
    parsed = JSON.parse(msg)
    Rails.logger.info "Parsed redis message: #{parsed}"
    FavoritesPoller.remove(parsed['oauth_token'])
  }
}


