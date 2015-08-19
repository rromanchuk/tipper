class SessionsController < ApplicationController
  def create
    Rails.logger.info auth_hash[:provider].to_yaml
    redirect_to "/?code=#{auth_hash[:provider][:token]}"
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end