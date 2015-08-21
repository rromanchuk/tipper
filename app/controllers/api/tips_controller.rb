module Api
  class TipsController < Api::BaseController
    skip_before_filter :require_user!

    def show
      render json: Tip.new(tip)
    end

    def tip
      @tip ||= Tip.find_by_txid(params[:id])
    end
  end
end
