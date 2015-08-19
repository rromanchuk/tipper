class SessionsController < ApplicationController
  def create
    redirect_to '/'
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end