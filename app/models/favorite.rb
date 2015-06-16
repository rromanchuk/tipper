class Favorite

  def self.batchWrite(collection, currentUser)
    putRequests = []
    collection.each do |tweet|
      putRequests << { put_request:
        { item:
          { "TweetID": tweet.id.to_s,
            "TweetJSON": tweet.to_json, 
            "CreatedAt": tweet.created_at.to_i,
            "FromUserID": currentUser["UserID"],
            "FromTwitterID": currentUser["TwitterUserID"],
            "FromTwitterUsername": currentUser["TwitterUsername"],
            "FromTwitterPofileImage": currentUser["ProfileImage"],
            "ToTwitterID": tweet.user.id.to_s,
            "ToTwitterUsername": tweet.user.screen_name,
            "ToTwitterPofileImage": tweet.user.profile_image_url.to_s,
          } 
        } 
      }
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