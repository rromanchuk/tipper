$stdout.sync = true
class TwitterFavorites

  def initialize
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "***REMOVED***"
      config.consumer_secret     = "DCL7zOahnqqH7DLAy6VMlCn5ZH866Nwylb5YYmInuue6MR510I"
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

  def self.start
    User.all.items.each do |user|
      f = TwitterFavorites.new
      f.client.access_token        = user["TwitterAuthToken"]
      f.client.access_token_secret = user["TwitterAuthSecret"]
      favorites = f.client.get_all_favorites
      favorites.each_slice(25).each do |chunkedFavorites|
        Favorite.batchWrite(chunkedFavorites, user["TwitterUserID"])
      end
      favorites
    end
  end

  def self.start_for_user(twitterId)
    user = User.find(twitterId)
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
    puts response.inspect
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end
end



class FetchFavoritesWorker
  def initialize
    #test_event
    puts "Starting event machine for FetchFavorites"
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
    sqs.send_message(queue_url: SQSQueues.fetch_favorites, message_body: { "TwitterUserID": "***REMOVED***" }.to_json )
  end

  def sqs
    @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def queue
    @queue ||= SQSQueues.fetch_favorites
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
      TwitterFavorites.start_for_user(json["TwitterUserID"])
      delete(receipt_handle)
    end
  end

  def delete(handle)
    resp = sqs.delete_message( queue_url: queue, receipt_handle: handle )
  end
end

FetchFavoritesWorker.new