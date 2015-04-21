
module Api
  class MeController < Api::BaseController
    skip_before_filter :require_user!, only: [:create]

    def create
      @resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: "us-east-1:71450ec4-894b-4e51-bfbb-35a012b5b514",
        identity_id:  params[:identity_id],
        # required
        logins: { "com.ryanromanchuk.tipper" => twitterId },
        token_duration: 1)


      unless User.find(twitterId)
         User.create_user(twitterId, username)
      end

      item = User.update_user(twitterId, attributes_to_update)
      fetch_favorites

      render json: item
    end


    def show
      render json: current_user
    end

    private
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

    def attributes_to_update
      {
        "TwitterAuthToken" => {
          value: twitter_auth_token
        },
        "TwitterAuthSecret" => {
          value: twitter_auth_secret
        },
        "CognityIdentity" => {
          value: @resp.identity_id
        },
        "CognitoToken" => {
          value: @resp.token
        }
      }
    end

    def fetch_favorites
      sqs.send_message(queue_url: SQSQueues.fetch_favorites, message_body: { "TwitterUserID": twitterId }.to_json )
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

  end
end
