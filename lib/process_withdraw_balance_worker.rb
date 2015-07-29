class ProcessWithdrawBalanceWorker

  def queue
    @queue ||= SqsQueues.withdraw_balance
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def logger
    @logger ||= begin
      _logger = Rails.logger
      _logger.progname = "process_withdraw_balance_worker"
      _logger
    end
  end

  def notify_sender(fromUser)
    return unless fromUser["EndpointArn"]
    begin
      message = "Your withdraw request of #{fromUser["BitcoinBalanceBTC"]}BTC is complete."
      apns_payload = { "aps" => { "alert" => message, "badge" => 1 }, "message" => {"title" => "Withdrawal complete", "subtitle" => message, "type" => "success"} }.to_json
      resp = sns.publish(
        target_arn: fromUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter => e
      logger.error "Aws::SNS::Errors::InvalidParameter"
      Bugsnag.notify(e, {:severity => "error"})
    end
  end

  def notify_sender_fail(fromUser)
    return unless fromUser["EndpointArn"]
    begin
      message = "Your withdraw request of #{fromUser["BitcoinBalanceBTC"]}BTC failed. Try again?"
      apns_payload = { "aps" => { "alert" => message, "badge" => 1 }, "message" => {"title" => "Withdrawal failed", "subtitle" => message, "type" => "error"} }.to_json
      resp = sns.publish(
        target_arn: fromUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter => e
      logger.error "Aws::SNS::Errors::InvalidParameter"
      Bugsnag.notify(e, {:severity => "error"})
    end
  end

  def initialize
    logger.info "Starting event machine for ProcessWithdrawBalanceWorker"
    #test_event
    EventMachine.run do
      EM.add_periodic_timer(25.0) do
        #logger.info "Ready to process tasks.."
        messages = receive
        #logger.info "Found message #{messages}"
        process_messages(messages)
      end
    end
  end

  def receive
    begin
      resp = sqs.receive_message(
        queue_url: queue,
        wait_time_seconds: 20,
      )
      messages = resp.messages.map do |message|
        { receipt_handle: message.receipt_handle, message: JSON.parse(message.body) }
      end
      messages
    rescue Aws::SQS::Errors::ServiceError => e
      # rescues all errors returned by Amazon Simple Queue Service
      Bugsnag.notify(e, {:severity => "error"})
    end
  end

  def process_messages(messages)
    messages.each do |message|
      receipt_handle = message[:receipt_handle]
      json = message[:message]

      logger.info "process_messages: #{json}"
      fromUser = User.find_by_twitter_id(json["TwitterUserID"])
      fromBitcoinAddress = fromUser["BitcoinAddress"]
      toBitcoinAddress = json["ToBitcoinAddress"]

      txid = B.withdraw(fromBitcoinAddress, toBitcoinAddress)
      if txid
        Withdraw.create(fromUser, toBitcoinAddress, txid)
        notify_sender(fromUser)
      else
        notify_sender_fail(fromUser)
      end

      delete(receipt_handle)
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end

end
ProcessWithdrawBalanceWorker.new