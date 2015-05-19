class ProcessWalletNotifications
  def logger
    @logger ||= begin
      _logger = Rails.logger
      _logger.progname = "process_withdraw_balance_worker"
      _logger
    end
  end

  def queue
    @queue ||= SqsQueues.wallet_notify
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def notify_admins(tx)
    begin
      message = "#{tx["category"]}: #{tx["amount"]}"
      resp = sns.publish(
        topic_arn: "arn:aws:sns:us-east-1:080383581145:WalletTransaction",
        message_structure: "json",
        message: {"default" => message, "sms": message }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    end

    AdminMailer.wallet_notify(tx).deliver_now
  end

  def notify_users(transaction)
    transaction["details"].each do |tx|
      
    end
  end

  def initialize
    logger.info "Starting event machine for ProcessWalletNotifications"
    #test_event
    EventMachine.run do
      EM.add_periodic_timer(25.0) do
        logger.info "Ready to process tasks.."
        messages = receive
        logger.info "Found message #{messages}"
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
    rescue Aws::SQS::Errors::ServiceError
    # rescues all errors returned by Amazon Simple Queue Service
    end
  end

  def process_messages(messages)
    messages.each do |message|
      receipt_handle = message[:receipt_handle]
      json = message[:message]
      logger.info "process_messages: #{json}"
      transaction = B.client.gettransaction(transaction["txid"])

      tx = Transaction.create(transaction)
      if tx["confirmations"] == 0
        notify_admins(tx)
      end
      delete(receipt_handle)
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end

end
ProcessWalletNotifications.new