class TipperBot

  def post_tip_on_twitter(fromUser, toUser, txid)
    message = "@#{fromUser["TwitterUsername"]} just sent @#{toUser["TwitterUsername"]} #{B::TIP_AMOUNT_UBTC.to_i}μBTC  https://blockchain.info/tx/#{txid}"
    tipper_bot_client.update(message)
  end

  def post_fund_on_twitter(username, txid)
    message = "@#{username} Transfer of #{B::FUND_AMOUNT_UBTC.to_i}μBTC complete. https://blockchain.info/tx/#{txid}"
    tipper_bot_client.update(message)
  end

  def tipper_bot_client
    @tipper_bot_client ||= begin
      tipper_bot = User.find_tipper_bot
        Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
        config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
        config.access_token        = tipper_bot["TwitterAuthToken"]
        config.access_token_secret = tipper_bot["TwitterAuthSecret"]
      end
    end
  end

end