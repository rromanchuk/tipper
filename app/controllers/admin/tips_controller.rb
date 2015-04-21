class Admin::TipsController < Admin::BaseController

  def index
    @paginated_tips = Tip.all
  end

  protected

end
