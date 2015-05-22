class Admin::BitcoinAccountsController < Admin::BaseController
  
  def balance
    @balance = B.totalBalance
  end

  def index
    @accounts = B.client.listaccounts
  end

  def recent
    @transactions = B.recent
  end

  def addresses
    @addresses = B.client.listreceivedbyaddress
  end

  def unspent
    @unspents = B.unspent(params[:id])
  end

  def network
    @network = B.client.getpeerinfo
  end

  protected

end
