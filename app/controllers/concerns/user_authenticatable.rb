module UserAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_filter :require_user!
    helper_method :current_user
  end

  protected

  def authenticate_user_from_token
    Rails.logger.info "LOGIN PARAMS: #{login_params}"
    Rails.logger.info "authenticate_user_from_token #{user["token"]} != #{auth_token} OR #{user["TwitterAuthToken"]} != #{auth_token}"
    raise ActionController::InvalidAuthenticityToken if user["token"] != auth_token && user["TwitterAuthToken"] != auth_token
    user
  rescue ActionController::InvalidAuthenticityToken => e
    Rollbar.error(e)
    false
  rescue ActionController::ParameterMissing => e
    Rollbar.error(e)
    false
  end

  def require_user!
    unless current_user
      return render json: {error: "Invalid credentials"}, status: 401
    end
  end

  def current_user
    @current_user ||= authenticate_user_from_token
  end

  def login_params
    @login_params ||= begin
      if request.authorization.present?
        params[:twitter_id] = ActionController::HttpAuthentication::Basic.user_name_and_password(request)[0].strip
        params[:auth_token] = ActionController::HttpAuthentication::Basic.user_name_and_password(request)[1].strip
        params
      else
        raise ActionController::InvalidAuthenticityToken
      end
    end
  end

  def user
    @user ||= User.find_by_twitter_id(twitter_id)
  end

  def twitter_id
    login_params.require(:twitter_id)
  end

  def bitcoin_address
    Rails.logger.info "bitcoin_address getter: #{current_user["BitcoinAddress"]}"
    if current_user["BitcoinAddress"]
      current_user["BitcoinAddress"]
    else 
      Rails.logger.info "bitcoin_address was nil, setting...."
      @current_user = User.set_btc_address(current_user)
      current_user["BitcoinAddress"]
    end
  end

  def cognito_identity
    user["CognitoIdentity"]
  end

  def user_id
    user["UserID"]
  end

  def auth_token
    login_params.require(:auth_token)
  end

  def db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end