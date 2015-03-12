
module Api
  require "application_responder"
  class BaseController < ActionController::Base
    self.responder = ApplicationResponder
    respond_to :json

    #protect_from_forgery with: :null_session

  end
end
