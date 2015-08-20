class IndexController < ApplicationController
  def index
    rev = Redis.current.lindex("tipper", 0)
    index_text = Redis.current.get(rev)
    Rails.logger.info form_authenticity_token
    index_text = index_text.gsub('CSRF-TOKEN', form_authenticity_token)
    render text: index_text
  end
end