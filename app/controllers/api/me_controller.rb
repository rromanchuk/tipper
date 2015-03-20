
module Api
  class MeController < Api::BaseController
    skip_before_filter :require_user!, only: [:create]

    def create
      resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: "us-east-1:71450ec4-894b-4e51-bfbb-35a012b5b514",
        identity_id:  params[:identity_id],
        # required
        logins: { "com.ryanromanchuk.tipper" => twitterId },
        token_duration: 1)
      token = SecureRandom.urlsafe_base64(30)
      bitcoin_address = B.getNewUserAddress
      generateUser(token, bitcoin_address, resp.identity_id)
      render json: {token: resp.token, identity_id: resp.identity_id, bitcoin_address: bitcoin_address, bitcoin_balance: B.balance(bitcoin_address), authentication_token: token }
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

    def updateProfileData

    end

    def generateUser(token, bitcoin_address, cognito_identity)
      resp = db.put_item(
        table_name: "TipperBitcoinAccounts",
        item: {
          "TwitterUserID" => twitterId,
          "token" => token,
          "TwitterUsername" => username,
          "BitcoinAddress" => bitcoin_address,
          "TwitterUsername" => username,
          "CognityIdentity" => cognito_identity,
        })
    end

    def db
      @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

    def sync
      @sync ||=  Aws::CognitoSync::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

  end
end
