module Api
  class BController < Api::BaseController
    skip_before_filter :require_user!

    def balance
      balance = B.balance(params[:username])
      render json: balance
    end

    def address
      address = B.addressForTwitterUsername(params[:username])
      render json: {bitcoin_address: address, username: username}
    end

    def accounts
      accounts = B.client.listaccounts
      render json: {accounts: accounts}
    end

    private 
    def username
      params[:username]
    end
  end
end
