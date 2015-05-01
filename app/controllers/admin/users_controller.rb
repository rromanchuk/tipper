class Admin::UsersController < Admin::BaseController

  def index
    if params[:filter] == "active"
      @paginated_users = User.find_active
    else
      @paginated_users = User.all
    end
    
  end

  def show
    @item = User.find(params[:id])
  end

  protected

end
