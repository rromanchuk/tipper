$stdout.sync = true

def logger
  @logger ||= begin 
    _logger = Rails.logger
    _logger.progname = "fetch_favorites_worker.rb"
    _logger
  end
end

class TwitterFavorites

  def initialize
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    end
    @client = client

    def client.get_all_favorites
      collect_with_max_id do |max_id|
        options = {count: 200}
        options[:max_id] = max_id unless max_id.nil?
        favorites(options)
      end
    end
  end

  def client
    @client
  end

  def self.start_for_user(user_id)
    user = User.find(user_id)
    f = TwitterFavorites.new
    f.client.access_token        = user["TwitterAuthToken"]
    f.client.access_token_secret = user["TwitterAuthSecret"]
    favorites = f.client.get_all_favorites
      favorites.each_slice(25).each do |chunkedFavorites|
        Favorite.batchWrite(chunkedFavorites, user)
      end
    favorites
  end

  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    logger.info response.inspect
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end
end



class FetchFavoritesWorker
  def initialize
    #test_event
    logger.info "Starting event machine for FetchFavorites"
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
    sqs.send_message(queue_url: SqsQueues.fetch_favorites, message_body: { "TwitterUserID": "14078827" }.to_json )
    sqs.send_message(queue_url: SqsQueues.fetch_favorites, message_body: { "TwitterUserID": "14764725" }.to_json )
    sqs.send_message(queue_url: SqsQueues.fetch_favorites, message_body: { "TwitterUserID": "11916702" }.to_json )
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def queue
    @queue ||= SqsQueues.fetch_favorites
  end

  def update_favorites_queue
    @queue ||= SqsQueues.update_favorites
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
      TwitterFavorites.start_for_user(json["UserID"])
      delete(receipt_handle)
    end
  end


  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end
end

FetchFavoritesWorker.new