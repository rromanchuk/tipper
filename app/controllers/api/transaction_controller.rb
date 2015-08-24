module Api
  class TransactionsController < Api::BaseController
    skip_before_filter :require_user!

    def show
      render json: {transaction: Transaction.new(transaction)}
    end

    protected
    def transaction
      @transaction ||= Transaction.update_transaction(params[:id])
    end
  end
end
