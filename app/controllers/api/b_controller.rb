module Api
  class BController < Api::BaseController
    skip_before_filter :require_user!

    def balance
      balance = B.client.client
      render json: balance
    end

    def accounts
      accounts = B.client.listaccounts
      render json: {accounts: accounts}
    end

    private 
    def username
      params.require(:username)
    end
  end
end
