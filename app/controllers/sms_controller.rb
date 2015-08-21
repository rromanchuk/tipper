require 'twilio-ruby'
require 'e164'
class SmsController < ApplicationController
  
  def download
    to_number = params[:sms][:to]
    twilio.messages.create(
      from: '+16604198197',
      to: E164.normalize(to_number),
      body: body
    )
    render json: {'sms': {body: body, id: to_number, to: to_number, from: from}}
  end

  private

  def body
    @body ||= 'Download tipper now from https://itunes.apple.com/us/app/tipper-micro-payments/id986575823'
  end

  def twilio
    @twilio ||= Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
  end
end