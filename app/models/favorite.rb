class Favorite

  def self.batchWrite(collection, currentUser)
    putRequests = []
    collection.each do |tweet|
      putRequests << { put_request: { item: { "TweetID": "#{currentUser["TwitterUserID"]}-#{tweet.id.to_s}", 
        "TweetJSON": tweet.to_json, 
        "CreatedAt": tweet.created_at.to_i, 
        "TipperUserID": currentUser["TwitterUserID"],
        "FromTwitterID": currentUser["TwitterUserID"],
        "ToTwitterID": tweet.user.id.to_s,
        "ToTwitterUsername": tweet.user.screen_name } } }
    end
    resp = db.batch_write_item(
      # required
      request_items: {
        "TipperTwitterFavorites" => putRequests
      },
    )
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    User.db
  end
end