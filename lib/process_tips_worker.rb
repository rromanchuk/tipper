
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

  def restClient
    @restClient ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = "***REMOVED***"
      config.consumer_secret     = "DCL7zOahnqqH7DLAy6VMlCn5ZH866Nwylb5YYmInuue6MR510I"
    end
  end

  def tipper_bot_client
    tipper_bot = User.find_tipper_bot
    @tipper_bot_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = "***REMOVED***"
      config.consumer_secret     = "DCL7zOahnqqH7DLAy6VMlCn5ZH866Nwylb5YYmInuue6MR510I"
      config.access_token        = tipper_bot["TwitterAuthToken"]
      config.access_token_secret = tipper_bot["TwitterAuthSecret"]
    end
  end

  def tweetObject(tweetId)
    restClient.status(tweetId)
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

  def notify_receiver(fromUser, toUser)
    return unless toUser["EndpointArn"]
    begin
      apns_payload = { "aps" => { "alert" => "You just received 1000μBTC from #{fromUser["TwitterUsername"]}.", "badge" => 1 } }.to_json
      resp = sns.publish(
        target_arn: toUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => "You just received 1000μBTC from #{fromUser["TwitterUsername"]}.", "APNS_SANDBOX": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      puts "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter
      puts "Aws::SNS::Errors::InvalidParameter"
    end
  end

  def notify_sender(fromUser, toUser)
    return unless fromUser["EndpointArn"]
    begin
      apns_payload = { "aps" => { "alert" => "You just sent 1000μBTC to #{toUser["TwitterUsername"]}.", "badge" => 1 } }.to_json
      resp = sns.publish(
        target_arn: fromUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => "You just sent 1000μBTC to #{toUser["TwitterUsername"]}.", "APNS_SANDBOX": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      puts "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter
      puts "Aws::SNS::Errors::InvalidParameter"
    end
  end

  def publish_from_problem(user)
    return unless user["EndpointArn"]
    begin
      apns_payload = { "aps" => { "alert" => "Opps, we weren't able to send the tip. Low balance?", "badge" => 1 } }.to_json
      resp = sns.publish(
        target_arn: user["EndpointArn"],
        message_structure: "json",
        message: {"default" => "Opps, we weren't able to send the tip. Low balance?", "APNS_SANDBOX": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      puts "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter
      puts "Aws::SNS::Errors::InvalidParameter"
    end
  end

  def post_on_twitter(fromUser, toUser)
    message = "@#{fromUser["TwitterUsername"]} just sent @#{toUser["TwitterUsername"]} 1000μBTC"
    tipper_bot_client.update(message)
  end

  def process_messages(messages)
    messages.each do |message|
      receipt_handle = message[:receipt_handle]
      json = message[:message]
      puts "process_messages: #{json}"

      fromUser = User.find(json["FromTwitterID"])
      toUser = User.find(json["ToTwitterID"])

      tweet = tweetObject(json["TweetID"])

      puts "fromUser:"
      puts fromUser.to_yaml
      unless toUser # If the user doesn't exist create a stub account
        toUser = User.create_user(json["ToTwitterID"], tweet.user.screen_name)
      end
      puts "toUser:"
      puts toUser.to_yaml

      # Publish the actual tip action to the bitcoind node
      txid = B.tip_user(fromUser["BitcoinAddress"], toUser["BitcoinAddress"])


      if txid
        resp = Tip.new_tip(tweet, fromUser, toUser, txid)

        # Send success notifications
        notify_sender(fromUser, toUser)
        notify_receiver(fromUser, toUser)
        delete(receipt_handle)
        post_on_twitter(fromUser, toUser)
      else
        # Send failure notifications
        publish_from_problem(fromUser)
        delete(receipt_handle)
      end
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end
end
ProcessTipWorker.new