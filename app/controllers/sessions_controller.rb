class SessionsController < ApplicationController
  def create
    Rails.logger.info auth_hash.to_yaml
    redirect_to '/'
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end