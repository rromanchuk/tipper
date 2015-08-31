module Api
  class ChargesController < Api::BaseController

    rescue_from Stripe::CardError, :with => :raise_card_error

    def new
    end

    def create
      # Amount in cents
      money = amount.to_money
      @amount = money.cents

      customer = Stripe::Customer.create(
        :card  => params[:stripeToken]
      )

      charge = Stripe::Charge.create(
        :customer    => customer.id,
        :amount      => @amount,
        :description => 'Tipper refill',
        :currency    => 'usd'
      )


      fund_account
      NotifyAdmin.fund_event(current_user["TwitterUsername"])

      render json: current_user
    end

    private

    def raise_card_error(error)
      render :json => {:error => error.message}, :status => :internal_server_error
    end

    def amount
      params.require(:amount)
    end

    def fund_account
      sqs.send_message(queue_url: SqsQueues.fund, message_body: current_user.to_json )
    end

    def sqs
      @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
    end

  end
end
