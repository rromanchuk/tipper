module UserAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_filter :require_user!
    helper_method :current_user
  end

  protected

  def authenticate_user_from_token
    
    Rails.logger.info login_params.inspect
    resp = db.get_item(
      table_name: "TipperBitcoinAccounts",
      key: {
        "TwitterUserID" => login_params[:twitter_id]
        })
    Rails.logger.info resp.item
    params[:bitcoin_address] = 
    raise ActionController::InvalidAuthenticityToken if params[:token] != resp.item["token"]
    resp
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

  def db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end