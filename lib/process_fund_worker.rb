class ProcessFundWorker
  def logger
    @logger ||= begin
      _logger = Rails.logger
      _logger.progname = "process_fund_worker"
      _logger
    end
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def publish_from_problem(user)
    return unless user["EndpointArn"]
    begin

      message = "Opps, there was a problem funding your account. Our support staff will contact you shortly."
      apns_payload = { "aps" => { "alert" => message, "badge" => 1 }, 
                      "user" => { "TwitterUserID" => user["TwitterUserID"] }, 
                      "message" => {"title" => "Ooops!", "subtitle" => message, "type" => "error"} }.to_json

      resp = sns.publish(
        target_arn: user["EndpointArn"],
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
      # TODO: remove user's endpoint from dynamo, it's invalid
    rescue Aws::SNS::Errors::InvalidParameter => e
      logger.error "Aws::SNS::Errors::InvalidParameter"
      Rollbar.error(e)
    end
  end


  def fund_user(user)
    logger.info "process_messages: #{user}"

    txid = B.fundUser(user["BitcoinAddress"])
    if txid
      user = User.update_balance(user)
      transaction = B.client.gettransaction(txid)
      transaction = Transaction.create(transaction, nil, user)
      NotifyUser.notify_fund_event(user)
      TipperBot.new.post_fund_on_twitter(user["TwitterUsername"], txid)
    else
      # do not delete message on failure
    end
  end

end


pf = ProcessFundWorker.new
EM.run {
  # Subscribe to new users.
  Rails.logger.info "Subscribing to funding events"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])
  redis.pubsub.subscribe("fund_event") { |msg|
    parsed = JSON.parse(msg)
    Rails.logger.info "Parsed redis message: #{parsed}"
    pf.fund_user(parsed)
  }
}