class IndexController < ApplicationController
  def index
  	rev = Redis.current.get('tipper:current')
    render text: Redis.current.get(rev)
  end

  private


end