class IndexController < ApplicationController
  def index
    rev = Redis.current.lindex("tipper", 0)
    render text: Redis.current.get(rev)
  end

  def session
    if auth_hash
      redirect_to "/?code=#{auth_hash[:extra][:access_token]}"
    else
      redirect_to "https://www.downloadtipper.com"
    end
  end


  protected

  def auth_hash
    request.env['omniauth.auth']
  end


end