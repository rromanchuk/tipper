
module Api
  class MeController < Api::BaseController
    skip_before_filter :require_user!, only: [:create]

    def create

      valid_twitter_credentials?

      Rails.logger.info "Find or create for twitterID: #{twitterId}...."
      user = User.find_by_twitter_id(twitterId)
      unless user
        user = User.create_user(attributes_to_update)
        fetch_favorites(user["UserID"])
      end

      Rails.logger.info "User: #{user.to_yaml}"

      resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: ENV["AWS_COGNITO_POOL"],
        identity_id:  user["CognitoIdentity"],
        # required
        logins: { "com.ryanromanchuk.tipper" => user["UserID"] },
        token_duration: 1)

      user["CognitoToken"] = resp.token
      user["CognitoIdentity"] = resp.identity_id
      update_cognito(user)


      Rails.logger.info "User: #{user.to_yaml}"
      redis.publish("new_users", {oauth_token: twitter_auth_token, oauth_token_secret: twitter_auth_secret}).errback { |e|
        p [:publisherror, e]
      }


      render json: user
    end


    def show
      render json: current_user
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
      {
        "TwitterAuthToken" => {
          value: twitter_auth_token
        },
        "TwitterAuthSecret" => {
          value: twitter_auth_secret
        },
        "IsActive" => {
          value: "X"
        }, 
        "ProfileImage" => {
          value: profile_image
        },
        "TwitterUserID" => {
          value: twitterId
        },
        "TwitterUsername" => {
          value: username
        }
      }
    end

    def update_cognito(user)
      resp = db.update_item(
        # required
        table_name: User::TABLE_NAME,
        # required
        key: {
          "UserID" => user["UserID"],
        },
        attribute_updates: {
          "CognitoToken" => {
            value: user["CognitoToken"],
            action: "PUT",
          },
          "CognitoIdentity" => {
            value: user["CognitoIdentity"],
            action: "PUT",
          },
        })
    end

    def fetch_favorites(user_id)
      sqs.send_message(queue_url: SqsQueues.fetch_favorites, message_body: { "TwitterUserID": twitterId, "UserID":  user_id }.to_json )
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

    def redis
      @redis ||= EM::Hiredis.connect(ENV["REDIS"])
    end

  end
end
