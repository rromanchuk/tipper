class IndexController < ApplicationController
  def index
    _index_text = get_index.gsub('CSRF-TOKEN', form_authenticity_token)
    render text: _index_text
  end

  private
  def get_index
    index_key = params[:index_key] || Redis.current.get("tipper:index:current")
    Redis.current.get("tipper:index:#{index_key}")
  end
end