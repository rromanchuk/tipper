module Api
  class BController < Api::BaseController
    def balance
      balance = B.client.balance(params[:username])
      render json: {balance: balance}
    end

    def address
      address = B.addressForTwitterUsername(params[:username])
      render json: {bitcoin_address: address, username: username}
    end

    def accounts
      accounts = B.listaccounts
      render json: {accounts: accounts}
    end

    private 
    def username
      params[:username]
    end
  end
end
