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

  def self.add user_id, oauth_token, oauth_token_secret
    if all.has_key?(oauth_token)
      Rails.logger.info "already have #{oauth_token}, not adding"
    else
      all[oauth_token] = FavoritesPoller.new(user_id, oauth_token, oauth_token_secret)
      all[oauth_token].start
    end
  end

  def self.remove oauth_token
    if fs = all[oauth_token]
      fs.stop
      all.delete(oauth_token)
    else
      Rails.logger.error "stream not found for #{oauth_token}"
    end
  end

  def initialize user_id, oauth_token, oauth_token_secret
    @oauth_token = oauth_token
    @oauth_token_secret = oauth_token_secret
    @user_id = user_id
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
    @user ||= User.find(@user_id)
  end

  def self.sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def self.lambda
    @lambda ||= Aws::Lambda::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def start
    @timer = EM.add_periodic_timer(rand(100..160)) do
      Rails.logger.info "About to invoke lambda for #{user["TwitterUsername"]}"
      publish
    end
  end

  def publish
    FavoritesPoller.lambda.invoke({
      function_name: "PollUserFavorites", # required
      invocation_type: "Event", # accepts Event, RequestResponse, DryRun
      payload: {twitter_username: user["TwitterUsername"], consumer_key: ENV["TWITTER_CONSUMER_KEY"], consumer_secret: ENV["TWITTER_CONSUMER_SECRET"], token: @oauth_token, secret: @oauth_token_secret, userId: user["UserID"], twitterId: user["TwitterUserID"]}.to_json,
    })
  end

  def stop
    @timer.cancel
  end
end

class AutoFavoriter
  
  def initialize(user_id)
    @user = User.find(user_id)
    User.tipped_from_us(@user)
  end

  def start
    # Find three of the new user's tweets
    tweets = user_client.user_timeline(user["TwitterUsername"], {count: 3, exclude_replies: true, include_rts: false})

    # Have tipper bot favorite them
    tweets.each do |tweet|
      tipper_bot_client.favorite(tweet.id)
      sleep 6
    end
  end

  def user
    @user
  end

  def user_client
    @user_client ||= User.client_for_user(@user)
  end

  def tipper_bot_client
    @tipper_bot_client ||= User.client_for_user(User.find_tipper_bot)
  end
end

active_users = User.find_active.items

EM.run {
  # Add existing users.
  # TODO On larger sets of users use EM::Iterator.
  active_users.each do |user|
    Rails.logger.info "TwitterAuthToken: #{user['TwitterAuthToken']}, TwitterAuthSecret: #{user['TwitterAuthSecret']}, AutomaticTippingEnabled: #{user['AutomaticTippingEnabled']}"
    if user['TwitterAuthToken'] && user['TwitterAuthSecret'] && user['AutomaticTippingEnabled'] == true
      Rails.logger.info "Adding: #{user["TwitterUsername"]}"
      FavoritesPoller.add user['TwitterAuthToken'], user['TwitterAuthSecret']
    elsif user['AutomaticTippingEnabled']
      Rails.logger.info "User has automatic tipping disabled"
    else
      Rails.logger.info "Skipping (no valid oauth in db): #{user["TwitterUsername"]}"
      NotifyUser.auth_token_expired(user)
    end
  end

  # Subscribe to new users.
  Rails.logger.info "Subscribing to new users"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])
  
  redis.pubsub.subscribe("auto_favorite_new_user") {|msg|
    Rails.logger.info "[REDIS] Onboarding new user by favoriting some tweets: #{msg}"
    parsed = JSON.parse(msg)
    AutoFavoriter.new(parsed["UserID"]).start
  }

  redis.pubsub.subscribe("new_users") { |msg|
    Rails.logger.info "[REDIS] Turning on favorites poller for user: #{msg}"
    parsed = JSON.parse(msg)
    FavoritesPoller.add(parsed['user_id'], parsed['oauth_token'], parsed['oauth_token_secret'])
  }

  Rails.logger.info "Subscribing to user diconnect events"
  redis.pubsub.subscribe("disconnect_user") { |msg|
    Rails.logger.info "[REDIS] Disconnecting user: #{msg}"
    parsed = JSON.parse(msg)
    FavoritesPoller.remove(parsed['oauth_token'])
  }
}


