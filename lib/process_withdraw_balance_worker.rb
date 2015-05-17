class ProcessWithdrawBalanceWorker

  def queue
    @queue ||= SQSQueues.wallet_notify
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def notify_admins(tx)
    begin
      message = "New wallet transactions amt: #{tx["amount"]}"
      resp = sns.publish(
        topic_arn: "arn:aws:sns:us-east-1:080383581145:WalletTransaction",
        message_structure: "json",
        message: {"default" => message, "sms": message }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      Rails.logger.error "Aws::SNS::Errors::EndpointDisabled"
    end

    AdminMailer.wallet_notify(tx).deliver_now
  end

  def initialize
    puts "Starting event machine for ProcessWithdrawBalanceWorker"
    #test_event
    EventMachine.run do
      EM.add_periodic_timer(25.0) do
        puts "Ready to process tasks.."
        messages = receive
        puts "Found message #{messages}"
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

      puts "process_messages: #{json}"
      fromUser = User.find(json["FromTwitterID"])
      fromBitcoinAddress = fromUser["BitcoinAddress"]
      toBitcoinAddress = json["ToBitcoinAddress"]

      txid = B.withdraw(fromBitcoinAddress, toBitcoinAddress)
      if txid

      else

      end

      delete(receipt_handle)
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end

end
ProcessWithdrawBalanceWorker.new