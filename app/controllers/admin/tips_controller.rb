class Admin::TipsController < Admin::BaseController

  def index
    if params[:filter] == "active"
      @paginated_tips = Tip.active
    else
      @paginated_tips = Tip.all
    end
  end

  protected

end
