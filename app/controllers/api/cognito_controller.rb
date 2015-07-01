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
      current_user = User.update(user_id, User::UPDATE_COGNITO_EXPRESSION, {":cognito_token": resp.token, ":cognito_identity": resp.identity_id } )

      render json: current_user
    end

    private
    def identity
      @cognitoidentity ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

  end
end
