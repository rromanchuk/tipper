module UserAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_filter :require_user!
    helper_method :current_user
  end

  protected

  def update_balance
    Rails.logger.info "balance is #{balance} bitcoinaddress is #{bitcoin_address}"

    update_expression = "SET BitcoinBalanceBTC = :bitcoin_balance_btc, UpdatedAt = :updated_at, IsActive = :is_active"
    update_values = {":bitcoin_balance_btc": balance[:btc], ":updated_at": Time.now.to_i, ":is_active": "X"}

    resp = db.update_item(
      # required
      table_name: User::TABLE_NAME,
      # required
      key: {
        "UserID" => user_id,
      },
      update_expression: update_expression,
      expression_attribute_values: update_values,
     )
  end

  def authenticate_user_from_token
    #Rails.logger.info "authenticate_user_from_token #{user}"
    Rails.logger.info "#{user["token"]} != #{auth_token}"
    raise ActionController::InvalidAuthenticityToken if user["token"] != auth_token
    update_balance
    user
  rescue ActionController::InvalidAuthenticityToken => e
    Bugsnag.notify(e, {:severity => "error"})
    false
  rescue ActionController::ParameterMissing => e
    Bugsnag.notify(e, {:severity => "error"})
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

  def user
    @user ||= User.find_by_twitter_id(twitter_id)
  end

  def twitter_id
    login_params.require(:twitter_id)
  end

  def bitcoin_address
    user["BitcoinAddress"]
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