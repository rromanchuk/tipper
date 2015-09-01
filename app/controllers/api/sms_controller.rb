require 'twilio-ruby'
module Api
  class SmsController < Api::BaseController
    skip_before_filter :require_user!
    def download
      to_number = Phony.normalize(params[:sms][:to])
      twilio.account.messages.create({from: from, to: to_number, body: body})
      render json: {'sms': {body: body, id: to_number, to: to_number, from: from}}
    end

    private

    def body
      @body ||= 'Download tipper now from https://itunes.apple.com/us/app/tipper-micro-payments/id986575823'
    end

    def from
      @from ||= '+16504198197'
    end

    def twilio
      @twilio ||= Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
    end
  end
end