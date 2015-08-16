class IndexController < ApplicationController
  def index
  	rev = Redis.current.lindex("tipper", 0)
    render text: Redis.current.get(rev)
  end

  private


end