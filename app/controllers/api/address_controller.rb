module Api
  class AddressController < Api::BaseController
    skip_before_filter :require_user!

    def create
      address = B.getNewUserAddress
      render json: {bitcoin_address: address, "BitcoinAddress": address}
    end

  end# SettingsController
end# API
