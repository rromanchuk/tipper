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
  end
end
