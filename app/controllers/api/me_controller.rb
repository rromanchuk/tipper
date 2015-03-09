
module Api
  class MeController < Api::BaseController


    def show

      resp = identity.get_open_id_token_for_developer_identity(
        # required
        identity_pool_id: "us-east-1:71450ec4-894b-4e51-bfbb-35a012b5b514",
        identity_id: nil,
        # required
        logins: { "com.ryanromanchuk.tipper" => params[:token] },
        token_duration: 1,)

      render json: {token: resp.token, identity_id: resp.identity_id}
    end

    private
    def identity
      @cognitoidentity ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

  end
end
