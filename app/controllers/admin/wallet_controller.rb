class Admin::WalletController < Admin::BaseController

  def withdrawls
    @paginated_withdrawls =  Withdraw.all
  end

  def transactions
    @paginated_transactions =  Transaction.all
  end

  protected

end
