module Api
  class BController < Api::BaseController
    def balance
      B.client.balance(params[:username])
      render json: {balance: 0}
    end

    def address
      B.client
      render json: {balance: 0}

    end
  end
end
