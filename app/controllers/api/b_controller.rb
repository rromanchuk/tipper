module Api
  class BController < Api::BaseController
    def balance
      balance = B.client.balance(params[:username])
      render json: {balance: balance}
    end

    def address
      address = B.addressForTwitterUsername(params[:username])
      render json: {bitcoin_address: address}
    end
  end
end
