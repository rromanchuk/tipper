
Rails.logger.info "-------------------  MARKER A"

class ProcessTipWorker
   def initialize
    logger.info "Starting event machine for ProcessTipWorker"
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

  def test_event
    sqs.send_message(queue_url: queue, message_body: { "FromTwitterID": "***REMOVED***", "ToTwitterID": "***REMOVED***", "TweetID": "***REMOVED***" }.to_json )
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def queue
    @queue ||= SqsQueues.new_tip
  end

  def tipper_bot
    TipperBot.new
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
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    end
  end

  def restClientForUser(fromUser)
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = fromUser["TwitterAuthToken"]
      config.access_token_secret = fromUser["TwitterAuthSecret"]
    end
  end

  def tweetObject(fromUser, tweetId)
    begin
      restClientForUser(fromUser).status(tweetId)
    rescue Twitter::Error::Unauthorized => e
      Rollbar.error(e)
      nil
    rescue Twitter::Error::Forbidden => e
      Rollbar.error(e)
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
    rescue Aws::SQS::Errors::ServiceError => e
    # rescues all errors returned by Amazon Simple Queue Service
      Rollbar.error(e)
    end
  end


  def process_messages(messages)
    messages.each do |message|
      receipt_handle = message[:receipt_handle]
      json = message[:message]
      logger.info "process_messages: #{json}"
      # Let's delete this message right away in case something goes wrong
      delete(receipt_handle)
      
      fromUser = User.find_by_twitter_id(json["FromTwitterID"])
      toUser = User.find_by_twitter_id(json["ToTwitterID"])

      # Fetch the tweet object
      tweet = tweetObject(fromUser, json["TweetID"])
      unless tweet
        NotifyUser.problem_tipping_user(fromUser)
        next
      end

      logger.info "fromUser:"
      logger.info fromUser.to_yaml
      unless toUser # If the user doesn't exist create a stub account
        profile_photo = tweet.user.profile_image_url.to_s ? tweet.user.profile_image_url.to_s : User::DEFAULT_PHOTO
        attributes = {":twitter_user_id": json["ToTwitterID"], ":twitter_username": tweet.user.screen_name, ":profile_image": profile_photo}
        toUser = User.create_stub_user(attributes)
      end

      logger.info "toUser:"
      logger.info toUser.to_yaml

      # Publish the actual tip action to the bitcoind node
      txid = B.tip_user(fromUser["BitcoinAddress"], toUser["BitcoinAddress"])


      if txid
        fromUser = User.update_balance(fromUser)
        toUser = User.update_balance(toUser)

        favorite = Tip.new_tip(tweet, fromUser, toUser, txid)
        transaction = B.client.gettransaction(txid)
        Transaction.create(transaction, fromUser, toUser)

        # Send success notifications
        NotifyUser.notify_sender(fromUser, toUser, favorite)
        NotifyUser.notify_receiver(fromUser, toUser, favorite)

        tipper_bot.post_tip_on_twitter(fromUser, toUser, txid, tweet.id.to_s)
      else
        Favorite.update_favorite(tweet, fromUser)
        # Send failure notifications, delete the sqs receipt so we don't keep retrying
        NotifyUser.problem_tipping_user(fromUser)
      end
      
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end
end
ProcessTipWorker.new
