module UserAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_filter :require_user!
    helper_method :current_user
    helper_method :bitcoin_address
  end

  protected

  def update_balance
    Rails.logger.info "balance is #{balance} bitcoinaddress is #{bitcoin_address}"
    resp = db.update_item(
      # required
      table_name: "TipperBitcoinAccounts",
      # required
      key: {
        "TwitterUserID" => twitter_id,
      },
      attribute_updates: {
        "BitcoinBalanceSatoshi" => {
          value: balance[:satoshi],
          action: "PUT",
        },
        "BitcoinBalanceMBTC" => {
          value: balance[:mbtc],
          action: "PUT",
        },
        "BitcoinBalanceBTC" => {
          value: balance[:btc],
          action: "PUT",
        },
      })
  end

  def authenticate_user_from_token
    Rails.logger.info "authenticate_user_from_token #{user}"

    raise ActionController::InvalidAuthenticityToken if user["token"] != auth_token
    update_balance
    user
  rescue ActionController::InvalidAuthenticityToken
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
    @user ||= User.find(twitter_id)
  end

  def twitter_id
    login_params.require(:twitter_id)
  end

  def bitcoin_address
    user.require("BitcoinAddress")
  end

  def auth_token
    login_params.require(:auth_token)
  end

  def db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end