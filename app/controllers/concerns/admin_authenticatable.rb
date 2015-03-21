module AdminAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_filter :require_admin!
    helper_method :current_admin
  end

  protected

  def require_admin!
    unless current_admin
      request_http_basic_authentication("Tipper")
    end
  end

  def current_admin
    @current_admin ||= authenticate_admin_with_http_basic
  end

  def authenticate_admin_with_http_basic
    authenticate_with_http_basic do |uuid, token|
      uuid == "admin" && token = "moonbeam"
    end
  end

end
