class SessionsController < ApplicationController
  def create
    Rails.logger.info auth_hash.to_json
    find_or_create
    redirect_to "/?code=#{auth_hash[:credentials][:token]}&uid=#{twitter_id}"
  end

  protected

  def find_or_create
    Rails.logger.info "Find or create for twitterID: #{twitter_id}...."

    user = User.find_by_twitter_id(twitter_id)
    cognito_resp = nil
    unless user
      user = User.create_user(attributes_to_update)
      cognito_resp = identity.get_id({
        account_id: "080383581145", # required
        identity_pool_id: ENV["AWS_COGNITO_POOL"],
        logins: {
          "www.twitter.com" => "#{twitter_auth_token};#{twitter_auth_secret}",
        },
      })
      NotifyAdmin.new_user(user["TwitterUsername"])
    else
      cognito_resp = identity.get_credentials_for_identity({
        identity_id: user["CognitoIdentity"], # required
        logins: {
          "www.twitter.com" => "#{twitter_auth_token};#{twitter_auth_secret}",
        },
      })
      Rails.logger.info "Found user:"
      Rails.logger.info user.to_yaml
      user = User.update(user["UserID"], User::UPDATE_EXPRESSION, attributes_to_update)
    end

    # Tokens may have changed, this user's stream may need to be restarted
    message = { oauth_token: user["TwitterAuthToken"], oauth_token_secret: user["TwitterAuthSecret"] }.to_json
    Redis.current.publish("new_users", message)
    Rails.logger.info "User: #{user.to_yaml}"

    

    user = User.update(user["UserID"], User::UPDATE_COGNITO_EXPRESSION, {":cognito_token": cognito_resp.token, ":cognito_identity": cognito_resp.identity_id} )
    Rails.logger.info "User: #{user.to_yaml}"
  end

  def identity
    @cognitoidentity ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def auth_hash
    @auth_hash ||= request.env['omniauth.auth']
  end

  def twitter_auth_token
    auth_hash[:credentials][:token]
  end

  def twitter_auth_secret
    auth_hash[:credentials][:secret]
  end

  def profile_image
    auth_hash[:info][:image]
  end

  def twitter_id
    auth_hash[:uid]
  end

  def twitter_username
    auth_hash[:info][:nickname]
  end

  def attributes_to_update
    {":twitter_auth_token": twitter_auth_token,
      ":twitter_auth_secret": twitter_auth_secret,
      ":is_active": "X",
      ":profile_image": profile_image,
      ":twitter_user_id": twitter_id,
      ":twitter_username": twitter_username
    }
  end
end