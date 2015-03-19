module Api
  class ChargesController < Api::BaseController
    def new
    end

    def create
      # Amount in cents
      @amount = 500

      customer = Stripe::Customer.create(
        :card  => params[:stripeToken]
      )

      charge = Stripe::Charge.create(
        :customer    => customer.id,
        :amount      => @amount,
        :description => 'Tipper refill',
        :currency    => 'usd'
      )
      send_bitcoin
      render json: charge

    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to charges_path
    end

    private
    def bitcoin_address
      params.require(:bitcoin_address)
    end

    def send_bitcoin
      B.fundUser(bitcoin_address)
    end


  end
end
