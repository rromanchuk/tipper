
module Api
  class MeController < Api::BaseController
    skip_before_filter :require_user!, only: [:create]

    def create

      resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: "us-east-1:71450ec4-894b-4e51-bfbb-35a012b5b514",
        identity_id:  params[:identity_id],
        # required
        logins: { "com.ryanromanchuk.tipper" => username },
        token_duration: 1)
      token = SecureRandom.urlsafe_base64(30)
      generateUser(token)
      render json: {token: resp.token, identity_id: resp.identity_id, bitcoin_address: B.addressForTwitterUsername(username), bitcoin_balance: B.balance(username), authentication_token: token }
    end


    private
    def identity
      @cognitoidentity ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

    def username
      params[:username]
    end

    def twitterId
      params[:twitter_id]
    end

    def generateUser(token)
      resp = db.put_item(
        table_name: "TipperUsers",
        item: {
          "TwitterUserID" => twitterId, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          "token" => token
        })
    end

    def db
      @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

  end
end
