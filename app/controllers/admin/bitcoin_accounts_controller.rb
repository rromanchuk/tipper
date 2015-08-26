class Admin::BitcoinAccountsController < Admin::BaseController
  
  def balance
    @wallet_balance = B.totalBalance
    @tipperbot_balance = B.balance(B::TIPPERBOT_ADDRESS)
    @reserves_balance = B.balance(B::RESERVES_ADDRESS)
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

  def reserve
    @unspents = B.unspent(B::RESERVES_ADDRESS)
    @tipperbot_unspents = B.unspent(B::TIPPERBOT_ADDRESS)
  end

  protected

end
