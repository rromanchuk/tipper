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
      # required
      table_name: "TipperUsers",
      # required
      key: {
        "token" => login_params, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
      },)
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
    Rails.logger.info params.inspect
    if request.authorization.present?
      params[:auth_token] = ActionController::HttpAuthentication::Basic.user_name_and_password(request)[1].strip
    else
      raise ActionController::InvalidAuthenticityToken
    end
  end

  def db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end