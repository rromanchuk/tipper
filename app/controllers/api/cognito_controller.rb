module Api
  class CognitoController < Api::BaseController
    def create
      resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: ENV["AWS_COGNITO_POOL"],
        identity_id: cognito_identity,
        # required
        logins: { "com.ryanromanchuk.tipper" => user_id },
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
        table_name: User::TABLE_NAME,
        # required
        key: {
          "UserID" => user_id,
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
