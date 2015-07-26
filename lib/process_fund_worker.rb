class ProcessFundWorker
  def logger
    @logger ||= begin
      _logger = Rails.logger
      _logger.progname = "process_fund_worker"
      _logger
    end
  end

  def queue
    @queue ||= SqsQueues.fund
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def initialize
    logger.info "Starting event machine for ProcessFundWorker"
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

  def notify_receiver(toUser)
    return unless toUser["EndpointArn"]
    begin
      message =  "Your deposit of #{B::FUND_AMOUNT_UBTC.to_i}μBTC is complete."
      apns_payload = { "aps" => { "alert" => message, "badge" => 1 }, 
                                  "type" => "funds_deposited", 
                                  "message" => {"title" => "Transfer complete", "subtitle" => message, "type" => "success"}, 
                                  "user" => { "TwitterUserID" => toUser["TwitterUserID"], "BitcoinBalanceBTC" => toUser["BitcoinBalanceBTC"] }, 
                                 }.to_json
      resp = sns.publish(
        target_arn: toUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
      # TODO: remove user's endpoint from dynamo, it's invalid
    rescue Aws::SNS::Errors::InvalidParameter => e
      logger.error "Aws::SNS::Errors::InvalidParameter"
      Bugsnag.notify(e, {:severity => "error"})
    end
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
      Bugsnag.notify(e, {:severity => "error"})
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
      toUser = message[:message]
      logger.info "process_messages: #{toUser}"

      txid = B.fundUser(toUser["BitcoinAddress"])
      if txid
        delete(receipt_handle)
        toUser = User.update_balance(toUser)
        transaction = B.client.gettransaction(txid)
        transaction = Transaction.create(transaction, nil, toUser)
        notify_receiver(toUser)
        TipperBot.new.post_fund_on_twitter(toUser["TwitterUsername"], txid)
      else
        # do not delete message on failure
      end
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end

end
ProcessFundWorker.new