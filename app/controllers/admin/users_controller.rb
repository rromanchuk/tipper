class Admin::UsersController < Admin::BaseController

  def index
    @paginated_users = User.all
  end

  protected

end
