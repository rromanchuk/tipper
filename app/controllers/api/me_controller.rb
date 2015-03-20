
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

      balance = B.balance(bitcoin_address)

      item ={ token: token,
        "TwitterUserID" => twitterId,
        "TwitterUsername" => username,
        "BitcoinAddress": bitcoin_address,
        "CognityIdentity": resp.identity_id,
        "CognitoToken": resp.token,
        "BitcoinBalanceSatoshi": balance[:satoshi],
        "BitcoinBalanceMBTC": balance[:mbtc],
        "BitcoinBalanceBTC": balance[:btc],
        "token": token
      }

      user = generateUser(item)
      render json: item
    end

    def show
      render json: current_user
    end

    def balance
      
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

    def bitcoin_address
      @bitcoin_address ||= B.getNewUserAddress
    end

    def token
      @token ||= SecureRandom.urlsafe_base64(30)
    end

    def updateProfileData

    end

    def generateUser(item)
      resp = db.put_item(
        table_name: "TipperBitcoinAccounts",
        item: item )
      resp.attributes
    end

    def db
      @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

    def sync
      @sync ||=  Aws::CognitoSync::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

  end
end
