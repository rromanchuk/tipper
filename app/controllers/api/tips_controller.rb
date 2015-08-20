module Api
  class TipsController < Api::BaseController
    def show
      render json: Tip.find_by_txid(params[:id])
    end

    # def txid
    #   params.require(:twitter_auth_secret)
    # end

  end
end
