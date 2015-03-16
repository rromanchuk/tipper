
module Api
  require "application_responder"
  class BaseController < ActionController::Base
    include UserAuthenticatable

    skip_before_action :verify_authenticity_token
    self.responder = ApplicationResponder
    respond_to :json
  end
end
