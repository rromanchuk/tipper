
class ProcessTipWorker
   def initialize
    logger.info "Starting event machine for ProcessTipWorker"
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

  def test_event
    sqs.send_message(queue_url: queue, message_body: { "FromTwitterID": "14764725", "ToTwitterID": "14078827", "TweetID": "342783" }.to_json )
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def queue
    @queue ||= SqsQueues.new_tip
  end

  def logger
    @logger ||= begin 
      _logger = Rails.logger
      _logger.progname = "process_tips_worker"
      _logger
    end
  end

  def restClient
    @restClient ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = "oGbPqpQeXUojn7macV7Ze9HvO"
      config.consumer_secret     = "iJDZtadyNK6BwXB49xszyBI6y748iERGEmUQM3veXNlcmKzqwJ"
    end
  end

  def restClientForUser(fromUser)
    Twitter::REST::Client.new do |config|
      config.consumer_key        = "oGbPqpQeXUojn7macV7Ze9HvO"
      config.consumer_secret     = "iJDZtadyNK6BwXB49xszyBI6y748iERGEmUQM3veXNlcmKzqwJ"
      config.access_token        = fromUser["TwitterAuthToken"]
      config.access_token_secret = fromUser["TwitterAuthSecret"]
    end
  end

  def tipper_bot_client
    tipper_bot = User.find_tipper_bot
    @tipper_bot_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = "oGbPqpQeXUojn7macV7Ze9HvO"
      config.consumer_secret     = "iJDZtadyNK6BwXB49xszyBI6y748iERGEmUQM3veXNlcmKzqwJ"
      config.access_token        = tipper_bot["TwitterAuthToken"]
      config.access_token_secret = tipper_bot["TwitterAuthSecret"]
    end
  end

  def tweetObject(fromUser, tweetId)
    begin
      restClientForUser(fromUser).status(tweetId)
    rescue Twitter::Error::Forbidden => e
      Bugsnag.notify(e, {:severity => "error"})
      nil
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

  def notify_receiver(fromUser, toUser)
    return unless toUser["EndpointArn"]
    begin
      message =  "You just received #{B.fund_amount_ubtc}μBTC from #{fromUser["TwitterUsername"]}."
      apns_payload = { "aps" => { "alert" => message, "badge" => 1 }, "user" => toUser }.to_json
      resp = sns.publish(
        target_arn: toUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter
      logger.error "Aws::SNS::Errors::InvalidParameter"
    end
  end

  def notify_sender(fromUser, toUser)
    return unless fromUser["EndpointArn"]
    begin
      message = "You just sent #{B.fund_amount_ubtc}μBTC to #{toUser["TwitterUsername"]}."
      apns_payload = { "aps" => { "alert" => message, "badge" => 1 }, "user" => fromUser }.to_json
      resp = sns.publish(
        target_arn: fromUser["EndpointArn"],
        message_structure: "json",
        message: {"default" => message, "APNS_SANDBOX": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter
      logger.error "Aws::SNS::Errors::InvalidParameter"
    end
  end

  def publish_from_problem(user)
    return unless user["EndpointArn"]
    begin
      apns_payload = { "aps" => { "alert" => "Opps, we weren't able to send the tip. Low balance?", "badge" => 1 }, "user" => user }.to_json
      resp = sns.publish(
        target_arn: user["EndpointArn"],
        message_structure: "json",
        message: {"default" => "Opps, we weren't able to send the tip. Low balance?", "APNS_SANDBOX": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    rescue Aws::SNS::Errors::InvalidParameter
      logger.error "Aws::SNS::Errors::InvalidParameter"
    end
  end

  def post_on_twitter(fromUser, toUser)
    message = "@#{fromUser["TwitterUsername"]} just sent @#{toUser["TwitterUsername"]} #{B.fund_amount_ubtc}μBTC"
    tipper_bot_client.update(message)
  end

  def process_messages(messages)
    messages.each do |message|
      receipt_handle = message[:receipt_handle]
      json = message[:message]
      logger.info "process_messages: #{json}"

      fromUser = User.find(json["FromTwitterID"])
      toUser = User.find(json["ToTwitterID"])

      tweet = tweetObject(fromUser, json["TweetID"])
      unless tweet
        publish_from_problem(fromUser)
        delete(receipt_handle)
        next
      end

      logger.info "fromUser:"
      logger.info fromUser.to_yaml
      unless toUser # If the user doesn't exist create a stub account
        toUser = User.create_user(json["ToTwitterID"], tweet.user.screen_name)
      end
      logger.info "toUser:"
      logger.info toUser.to_yaml

      # Publish the actual tip action to the bitcoind node
      txid = B.tip_user(fromUser["BitcoinAddress"], toUser["BitcoinAddress"])


      if txid
        resp = Tip.new_tip(tweet, fromUser, toUser, txid)
        transaction = B.client.gettransaction(txid)
        Transaction.create(transaction, fromUser, toUser)

        # Send success notifications
        notify_sender(fromUser, toUser)
        notify_receiver(fromUser, toUser)
        delete(receipt_handle)
        #post_on_twitter(fromUser, toUser)
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
