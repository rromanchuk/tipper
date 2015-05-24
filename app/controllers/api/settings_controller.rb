module Api
  class SettingsController < Api::BaseController
    skip_before_filter :require_user!

    def index
      render json: {fund_amount: B::FUND_AMOUNT, tip_amount: B::TIP_AMOUNT, fee_amount: B::FEE_AMOUNT}
    end

  end# SettingsController
end# API
