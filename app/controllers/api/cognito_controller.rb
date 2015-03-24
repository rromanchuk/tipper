module Api
  class CognitoController < Api::BaseController
    def create
      resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: "us-east-1:71450ec4-894b-4e51-bfbb-35a012b5b514",
        identity_id: cognito_identity,
        # required
        logins: { "com.ryanromanchuk.tipper" => twitter_id },
        token_duration: 1)

      current_user["CognitoToken"] = resp.token
      current_user["CognitoIdentity"] = resp.identity_id
      update_cognito
      render json: current_user
    end

    private
    def identity
      @cognitoidentity ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end
    
    def update_cognito
      resp = db.update_item(
        # required
        table_name: "TipperBitcoinAccounts",
        # required
        key: {
          "TwitterUserID" => twitter_id,
        },
        attribute_updates: {
          "CognitoToken" => {
            value: current_user["CognitoToken"],
            action: "PUT",
          },
          "CognitoIdentity" => {
            value: current_user["CognitoIdentity"],
            action: "PUT",
          },
        })
    end

  end
end
