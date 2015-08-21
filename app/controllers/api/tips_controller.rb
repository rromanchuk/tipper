module Api
  class TipsController < Api::BaseController
    skip_before_filter :require_user!

    def show
      render json: Tip.find_by_txid(params[:id])
    end
  end
end
