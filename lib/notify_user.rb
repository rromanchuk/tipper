class NotifyUser

  def self.send_debug_apn_to_me
    message = "This is a test push notification"
    user = User.find("1e6b27ea-3570-4bd5-854e-af7dc5e1bed8")
    Rails.logger.info "Sending test apn to #{endpoint}"
    apns_payload = { "aps" => { "alert" => message },
                                "type" => "tip_received",
                                "message" => {"title" => "Tip received", "subtitle" => message, "type" => "success"},
                                "user" => { "TwitterUserID" => user["TwitterUserID"], "BitcoinBalanceBTC" => user["BitcoinBalanceBTC"] },
                              }.to_json
      
    send_to_apns(user["UserID"], apns_payload, user["EndpointArns"], message)
  end

  def self.auth_token_expired(user)
    message = "Opps, we can't process your twitter stream until you login again."
    if user["EndpointArns"]
        apns_payload = { "aps" => { "alert" => message } }.to_json
        send_to_apns(user["UserID"], apns_payload, user["EndpointArns"], message)
    end

    Notification.create_problem(user["UserID"], "problem", message)
  end

  def self.problem_tipping_user(user)
    message = "Opps, we weren't able to send the tip. Low balance?"
    if user["EndpointArns"]
      apns_payload = { "aps" => { "alert" => "Opps, we weren't able to send the tip. Low balance?" },
                    "user" => { "TwitterUserID" => user["TwitterUserID"] },
                    "message" => {"title" => "Ooops!", "subtitle" => message, "type" => "error"} }.to_json
      send_to_apns(user["UserID"], apns_payload, user["EndpointArns"], message)
    end

    Notification.create_problem(user["UserID"], "low_balance", message)
  end

  def self.notify_receiver(fromUser, toUser, favorite)
    message =  "You just received 10¢ (#{B::TIP_AMOUNT_UBTC.to_i}μBTC) from #{fromUser["TwitterUsername"]}."
    if toUser["EndpointArns"]
      apns_payload = { "aps" => { "alert" => message },
                                  "type" => "tip_received",
                                  "message" => {"title" => "Tip received", "subtitle" => message, "type" => "success"},
                                  "user" => { "TwitterUserID" => toUser["TwitterUserID"], "BitcoinBalanceBTC" => toUser["BitcoinBalanceBTC"] },
                                  "favorite" => {"TweetID" => favorite["TweetID"], "FromTwitterID" => favorite["FromTwitterID"] } }.to_json
      send_to_apns(toUser["UserID"], apns_payload, toUser["EndpointArns"], message)
    end
    
    Notification.create(toUser["UserID"], "user_received_tip", message, favorite)
  end

  def self.notify_sender(fromUser, toUser, favorite)
    message = "You just sent 10¢ (#{B::TIP_AMOUNT_UBTC.to_i}μBTC) to #{toUser["TwitterUsername"]}."
    
    if fromUser["EndpointArns"]
      apns_payload = { "aps" => { "alert" => message },
                                    "type" => "tip_sent",
                                    "message" => {"title" => "Tip sent", "subtitle" => message, "type" => "success"},
                                    "user" => { "TwitterUserID" => fromUser["TwitterUserID"], "BitcoinBalanceBTC" => fromUser["BitcoinBalanceBTC"] },
                                    "favorite" => {"TweetID" => favorite["TweetID"], "FromTwitterID" => favorite["FromTwitterID"] } }.to_json
      send_to_apns(fromUser["UserID"], apns_payload, fromUser["EndpointArns"], message)
    end
    
    Notification.create(fromUser["UserID"], "user_sent_tip", message, favorite)
  end

  def self.notify_fund_event(user)
    message =  "Your deposit of #{B::FUND_AMOUNT_UBTC.to_i}μBTC is complete."
    if user["EndpointArns"]
      apns_payload = { "aps" => { "alert" => message },
                                    "type" => "funds_deposited",
                                    "message" => {"title" => "Transfer complete", "subtitle" => message, "type" => "success"},
                                    "user" => { "TwitterUserID" => user["TwitterUserID"], "BitcoinBalanceBTC" => user["BitcoinBalanceBTC"] },
                                   }.to_json
      send_to_apns(user["UserID"], apns_payload, user["EndpointArns"], message)
    end
    Notification.create(user["UserID"], "fund_event", message)
  end

  def self.notify_withdrawal(user)
    message = "Your withdraw request of #{user["BitcoinBalanceBTC"]}BTC is complete."
    if user["EndpointArns"]
      message = "Your withdraw request of #{user["BitcoinBalanceBTC"]}BTC is complete."
      apns_payload = { "aps" => { "alert" => message }, "message" => {"title" => "Withdrawal complete", "subtitle" => message, "type" => "success"} }.to_json
      send_to_apns(user["UserID"], apns_payload, user["EndpointArns"], message)
    end

    Notification.create(user["UserID"], "withdrawal_event", message)
  end

  def self.send_to_apns(user_id, payload, endpoints, message)
    endpoints.each do |endpoint|
      Rails.logger.info "Going to send notification #{endpoint}"
      send(user_id, payload, endpoint, message)
    end
  end

  def self.send(user_id, payload, endpoint, message)
    begin 
      resp = sns.publish(
        target_arn: endpoint,
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": payload, "APNS": payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      Rails.logger.error "Aws::SNS::Errors::EndpointDisabled"
      # TODO: remove user's endpoint from dynamo, it's invalid
      User.delete_endpoint_arns(user_id, [endpoint])
      sns.delete_endpoint({ endpoint_arn: endpoint })
    rescue Aws::SNS::Errors::InvalidParameter => e
      Rails.logger.error "Aws::SNS::Errors::InvalidParameter"
      Rollbar.info(e)
    rescue => e
      Rollbar.error(e)
    end
  end

  def self.sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end