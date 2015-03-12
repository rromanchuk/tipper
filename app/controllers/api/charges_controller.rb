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

      render json: charge

    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to charges_path
    end
  end
end
