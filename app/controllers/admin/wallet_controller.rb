class Admin::WalletController < Admin::BaseController

  def withdrawals
    @paginated_withdrawals =  Withdraw.all
  end

  def transactions
    @paginated_transactions =  Transaction.all
  end

  protected

end
