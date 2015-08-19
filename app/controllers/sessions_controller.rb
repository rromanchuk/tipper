class SessionsController < ApplicationController
  def create
    Rails.logger.info auth_hash.to_json
    redirect_to "/?code=#{auth_hash[:credentials][:token]}"
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end