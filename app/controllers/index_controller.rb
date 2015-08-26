class IndexController < ApplicationController
  def index
    check_revision
    _index_text = index_text.gsub('CSRF-TOKEN', form_authenticity_token)
    render text: _index_text
  end

  private
  def check_revision
    if rev != current_rev
      @current_rev = rev
      @index_text = Redis.current.get(current_rev)
    end
  end

  def rev
    Redis.current.lindex("tipper", 0)
  end

  def current_rev
    @current_rev
  end

  def index_text
    @index_text ||= Redis.current.get(current_rev)
  end
end