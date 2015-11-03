
module Api
  class MeController < Api::BaseController
    skip_before_filter :require_user!, only: [:create, :register]

    def tips

    end

    def disconnect
      message = { oauth_token: current_user["TwitterAuthToken"], oauth_token_secret: current_user["TwitterAuthSecret"] }.to_json
      User.turn_off_automatic_tipping(current_user)
      Redis.current.publish("disconnect_user", message)
      render json: {}
    end

    def connect
      fetch_favorites
      message = { oauth_token: current_user["TwitterAuthToken"], oauth_token_secret: current_user["TwitterAuthSecret"] }.to_json
      User.turn_on_automatic_tipping(current_user)
      Redis.current.publish("connect_user", message)
      render json: {}
    end

    def autotip
      send_onboarding_tips_from_us
      render json: {'me': Me.new(current_user) }
    end

    def show
      render json: {'me': Me.new(current_user) }
    end

    private

    def valid_twitter_credentials?
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
        config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
        config.access_token        = twitter_auth_token
        config.access_token_secret = twitter_auth_secret
      end
      client.current_user
    end

    def identity
      @cognitoidentity ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

    def username
      params.require(:username)
    end

    def twitterId
      params.require(:twitter_id)
    end

    def twitter_auth_token
      params.require(:twitter_auth_token)
    end

    def twitter_auth_secret
      params.require(:twitter_auth_secret)
    end

    def profile_image
      params.require(:profile_image)
    end

    def attributes_to_update
      {":twitter_auth_token": twitter_auth_token, 
        ":twitter_auth_secret": twitter_auth_secret, 
        ":is_active": "X", 
        ":profile_image": profile_image,
        ":twitter_user_id": twitterId, 
        ":twitter_username": username
      }
    end

    def fetch_favorites
      Redis.current.publish("fetch_favorites", {"UserID": current_user["UserID"]}.to_json)
    end

    def send_onboarding_tips_from_us
      Redis.current.publish("auto_favorite_new_user", {"UserID": current_user["UserID"]}.to_json) unless current_user["TippedFromUsAt"]
    end

    def db
      @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

    def sync
      @sync ||=  Aws::CognitoSync::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

    def sqs
      @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end


    # Deprecated
    def register
      valid_twitter_credentials?

      Rails.logger.info "Find or create for twitterID: #{twitterId}...."

      user = User.find_by_twitter_id(twitterId)

      unless user
        user = User.create_user(attributes_to_update)
      else
        Rails.logger.info "Found user:"
        Rails.logger.info user.to_yaml
        user = User.update(user["UserID"], User::UPDATE_EXPRESSION, attributes_to_update)
      end

      # Tokens may have changed, this user's stream may need to be restarted
      message = { oauth_token: user["TwitterAuthToken"], oauth_token_secret: user["TwitterAuthSecret"] }.to_json
      Redis.current.publish("new_users", message)
      Rails.logger.info "User: #{user.to_yaml}"


      render json: user
    end

  end
end
