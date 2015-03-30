
class ProcessTipWorker
   def initialize
    puts "Starting event machine for ProcessTipWorker"
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

  def test_event
    sqs.send_message(queue_url: queue, message_body: { "FromTwitterID": "***REMOVED***", "ToTwitterID": "***REMOVED***", "TweetID": "***REMOVED***" }.to_json )
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def queue
    @queue ||= SQSQueues.new_tip
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

  def publish(user)
    apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 1 } }.to_json
    resp = sns.publish(
      target_arn: user["EndpointArn"],
      message_structure: "json",
      message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload }.to_json
    )
    puts resp.inspect
  end

  def process_messages(messages)
    messages.each do |message|
      receipt_handle = message[:receipt_handle]
      json = message[:message]
      puts "process_messages: #{json}"
      fromUser = User.find(json["FromTwitterID"])
      toUser = User.find(json["ToTwitterID"])

      puts "fromUser: #{fromUser}"
      unless toUser
        toUser = User.create_user(json["ToTwitterUserID"])
      end
      puts "toUser: #{toUser}"

      txid = B.tip_user(fromUser["BitcoinAddress"], toUser["BitcoinAddress"])
      Tip.new_tip(json["TweetID"], json["FromTwitterID"], json["ToTwitterID"], txid)

      publish(fromUser)
      delete(receipt_handle)
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end
end
ProcessTipWorker.new