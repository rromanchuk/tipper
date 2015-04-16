class Admin::TipsController < Admin::BaseController

  def index
    @paginated_users = User.all
  end

  protected

end
