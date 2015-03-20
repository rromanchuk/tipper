module Api
  class BController < Api::BaseController
    skip_before_filter :require_user!

    def balance
      balance = B.totalBalance
      render json: balance
    end

    def addresses
      addresses = B.client.listreceivedbyaddress
      render json: addresses
    end

    def address_balance(address)
      balance B.address_balance(address)
      render json: balance
    end

    def accounts
      accounts = B.client.listaccounts
      render json: {accounts: accounts}
    end

    def recent
      recent = B.recent
      render json: {recent: recent}
    end

    private 
    def username
      params.require(:username)
    end

    def address
      params[:address]
    end
  end
end
