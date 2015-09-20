class NotifyUser

  def self.auth_token_expired(user)
    message = "Opps, we can't process your twitter stream until you login again."
    if user["EndpointArns"]
      user["EndpointArns"].each do |endpoint|
        apns_payload = { "aps" => { "alert" => message } }.to_json
        send(apns_payload, endpoint, message)
      end
    end

    Notification.create(user["UserID"], "problem", message)
  end

  def self.problem_tipping_user(user)
    message = "Opps, we weren't able to send the tip. Low balance?"
    if user["EndpointArns"]
      user["EndpointArns"].each do |endpoint|
        apns_payload = { "aps" => { "alert" => "Opps, we weren't able to send the tip. Low balance?" },
                      "user" => { "TwitterUserID" => user["TwitterUserID"] },
                      "message" => {"title" => "Ooops!", "subtitle" => message, "type" => "error"} }.to_json
        send(apns_payload, endpoint, message)
      end
    end

    Notification.create(user["UserID"], "low_balance", message)
  end

  def self.notify_receiver(fromUser, toUser, favorite)
    message =  "You just received #{B::TIP_AMOUNT_UBTC.to_i}μBTC from #{fromUser["TwitterUsername"]}."
    if toUser["EndpointArns"]
      toUser["EndpointArns"].each do |endpoint|
        apns_payload = { "aps" => { "alert" => message },
                                    "type" => "tip_received",
                                    "message" => {"title" => "Tip received", "subtitle" => message, "type" => "success"},
                                    "user" => { "TwitterUserID" => toUser["TwitterUserID"], "BitcoinBalanceBTC" => toUser["BitcoinBalanceBTC"] },
                                    "favorite" => {"TweetID" => favorite["TweetID"], "FromTwitterID" => favorite["FromTwitterID"] } }.to_json
        send(apns_payload, endpoint, message)
      end
    end
    
    Notification.create(toUser["UserID"], "user_received_tip", message)
  end

  def self.notify_sender(fromUser, toUser, favorite)
    message = "You just sent #{B::TIP_AMOUNT_UBTC.to_i}μBTC to #{toUser["TwitterUsername"]}."
    
    if fromUser["EndpointArns"]
      fromUser["EndpointArns"].each do |endpoint|
        apns_payload = { "aps" => { "alert" => message },
                                      "type" => "tip_sent",
                                      "message" => {"title" => "Tip sent", "subtitle" => message, "type" => "success"},
                                      "user" => { "TwitterUserID" => fromUser["TwitterUserID"], "BitcoinBalanceBTC" => fromUser["BitcoinBalanceBTC"] },
                                      "favorite" => {"TweetID" => favorite["TweetID"], "FromTwitterID" => favorite["FromTwitterID"] } }.to_json

        send(apns_payload, endpoint, message)
      end
    end
    
    Notification.create(fromUser["UserID"], "user_sent_tip", message)
  end

  def self.notify_fund_event(user)
    message =  "Your deposit of #{B::FUND_AMOUNT_UBTC.to_i}μBTC is complete."
    if user["EndpointArns"]
      user["EndpointArns"].each do |endpoint|
        apns_payload = { "aps" => { "alert" => message }, 
                                    "type" => "funds_deposited", 
                                    "message" => {"title" => "Transfer complete", "subtitle" => message, "type" => "success"}, 
                                    "user" => { "TwitterUserID" => user["TwitterUserID"], "BitcoinBalanceBTC" => user["BitcoinBalanceBTC"] }, 
                                   }.to_json
        send(apns_payload, endpoint, message)
      end
    end
    Notification.create(user["UserID"], "fund_event", message)
  end

  def self.notify_withdrawal(user)
    message = "Your withdraw request of #{fromUser["BitcoinBalanceBTC"]}BTC is complete."
    if user["EndpointArns"]
      user["EndpointArns"].each do |endpoint|
        message = "Your withdraw request of #{fromUser["BitcoinBalanceBTC"]}BTC is complete."
        apns_payload = { "aps" => { "alert" => message }, "message" => {"title" => "Withdrawal complete", "subtitle" => message, "type" => "success"} }.to_json
        resp = sns.publish(
          target_arn: endpoint,
          message_structure: "json",
          message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
        )
      end
    end

    Notification.create(user["UserID"], "withdrawal_event", message)
  end

  def self.send(payload, endpoint, message)
    begin 
      resp = sns.publish(
        target_arn: endpoint,
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": payload, "APNS": payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      Rails.logger.error "Aws::SNS::Errors::EndpointDisabled"
      # TODO: remove user's endpoint from dynamo, it's invalid
    rescue Aws::SNS::Errors::InvalidParameter => e
      Rails.logger.error "Aws::SNS::Errors::InvalidParameter"
      Bugsnag.notify(e, {:severity => "error"})
    end
  end

  def self.sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end