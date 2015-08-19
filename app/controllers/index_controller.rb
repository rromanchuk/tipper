class IndexController < ApplicationController
  def index
    rev = Redis.current.lindex("tipper", 0)
    index_text = Redis.current.get(rev)
    Rails.log.info session.inspect
    #index_text = index_text.gsub('CSRF-TOKEN')
    render text: index_text
  end

  # def session
  #   if auth_hash
  #     redirect_to "/?code=#{auth_hash[:extra][:access_token]}"
  #   else
  #     redirect_to "https://www.downloadtipper.com"
  #   end
  # end


  protected

  def auth_hash
    request.env['omniauth.auth']
  end


end