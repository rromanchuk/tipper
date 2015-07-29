module Api
  class AddressController < Api::BaseController
    skip_before_filter :require_user!

    def create
      render json: {bitcoin_address: B.getNewUserAddress}
    end

  end# SettingsController
end# API
