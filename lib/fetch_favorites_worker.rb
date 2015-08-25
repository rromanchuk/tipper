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
    if user["TwittterDeepCrawledAt"]
      logger.info "Skipping deep crawl. Already performed on #{user["TwittterDeepCrawledAt"]}"
    end
    User.deep_crawl_started(user)
    
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


EM.run {
  # Subscribe to new users.
  Rails.logger.info "Subscribing to favorites fetcher"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])
  redis.pubsub.subscribe("fetch_favorites") { |msg|
    Rails.logger.info "Found fetch favorite event: #{msg}"
    parsed = JSON.parse(msg)
    Rails.logger.info "Parsed redis message: #{parsed}"
    TwitterFavorites.start_for_user(parsed["UserID"])
  }
}