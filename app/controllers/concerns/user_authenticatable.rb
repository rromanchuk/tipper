module UserAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_filter :require_user!
    helper_method :current_user
  end

  protected

  def update_balance
    Rails.logger.info "update_balance: #{bitcoin_address}"
    if bitcoin_address
      Rails.logger.info "balance is #{balance} bitcoinaddress is #{bitcoin_address}"
      update_expression = "SET BitcoinBalanceBTC = :bitcoin_balance_btc, UpdatedAt = :updated_at, IsActive = :is_active"
      update_values = {":bitcoin_balance_btc": balance[:btc], ":updated_at": Time.now.to_i, ":is_active": "X"}
      User.update(user_id, update_expression, update_values)
    end
  end

  def authenticate_user_from_token
    user = User.find_by_twitter_id(twitter_id)
    Rails.logger.info "authenticate_user_from_token: #{login_params}"
    Rails.logger.info "authenticate_user_from_token #{user["token"]} != #{auth_token} OR #{user["TwitterAuthToken"]} != #{auth_token}"
    raise ActionController::InvalidAuthenticityToken if user["token"] != auth_token && user["TwitterAuthToken"] != auth_token
    update_balance
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

  def balance
    @balance ||= B.balance(bitcoin_address)
  end

  def twitter_id
    login_params.require(:twitter_id)
  end

  def bitcoin_address
    if current_user["BitcoinAddress"]
      current_user["BitcoinAddress"]
    else 
      @current_user = User.set_btc_address(current_user)
      current_user["BitcoinAddress"]
    end
  end

  def cognito_identity
    current_user["CognitoIdentity"]
  end

  def user_id
    current_user["UserID"]
  end

  def auth_token
    login_params.require(:auth_token)
  end

  def db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end