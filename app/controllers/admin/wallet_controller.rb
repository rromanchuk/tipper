class Admin::WalletController < Admin::BaseController

  def index
    if params[:filter] == "active"
      @paginated_users = User.find_active
    else
      @paginated_users = User.all
    end
    
  end

  def withdrawls
    @paginated_withdrawls =  Withdraw.all
  end

  protected

end
