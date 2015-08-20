require 'twilio-ruby'
class SmsController < ApplicationController
  
  def send
    twilio.messages.create(
      from: '+16604198197',
      to: to,
      body: body
    )
    render json: {'sms': {body: body, id: to, to: to, from: from}}
  end

  private

  def body
    @body ||= 'Download tipper now from https://itunes.apple.com/us/app/tipper-micro-payments/id986575823'
  end

  def twilio
    @twilio ||= Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
  end

  def to
    params.require(:sms).permit(:to)
  end
end