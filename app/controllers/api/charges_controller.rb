module Api
  class ChargesController < Api::BaseController
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
