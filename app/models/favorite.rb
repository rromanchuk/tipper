class Favorite

  def self.batchWrite(collection, currentUser)
    putRequests = []
    collection.each do |tweet|
      Rails.logger.info "Favorite#batchWrite updating favorite object..."
      update_favorite(tweet, currentUser)
      # putRequests << { put_request:
      #   { item:
      #     { "ObjectID": tweet.id.to_s,
      #       "Provider": "twitter",
      #       "TweetID": tweet.id.to_s,
      #       "TweetJSON": tweet.to_json, 
      #       "CreatedAt": tweet.created_at.to_i,
      #       "FromUserID": currentUser["UserID"],
      #       "FromTwitterID": currentUser["TwitterUserID"],
      #       "FromTwitterUsername": currentUser["TwitterUsername"],
      #       "FromTwitterProfileImage": currentUser["ProfileImage"],
      #       "ToTwitterID": tweet.user.id.to_s,
      #       "ToTwitterUsername": tweet.user.screen_name,
      #       "ToTwitterProfileImage": tweet.user.profile_image_url.to_s,
      #     }
      #   } 
      # }
    end
    # resp = db.batch_write_item(
    #   # required
    #   request_items: {
    #     "TipperTips" => putRequests
    #   },
    # )
  end

  def self.update_favorite(tweet, currentUser)
    resp = db.update_item(
      # required
      table_name: Tip::TABLE_NAME,
      return_values: "ALL_NEW",
      # required
      key: {
        "ObjectID" =>  tweet.id.to_s,
        "FromUserID" => currentUser["UserID"],
      },
      update_expression: "SET Provider = :provider, TweetID = :tweet_id, TweetJSON = :tweet_json, CreatedAt = :created_at, FromTwitterUsername = :from_twitter_username, FromTwitterProfileImage = :from_twitter_profile_image, ToTwitterUsername = :to_twitter_username, ToTwitterProfileImage = :to_twitter_profile_image",
      expression_attribute_values: {":provider": "twitter",
                                    ":tweet_id": tweet.id.to_s,
                                    ":tweet_json": tweet.to_json,
                                    ":created_at": tweet.created_at.to_i, 
                                    ":from_twitter_username": currentUser["TwitterUsername"],
                                    ":from_twitter_profile_image": currentUser["ProfileImage"],
                                    ":to_twitter_profile_image": tweet.user.profile_image_url.to_s,
                                    ":to_twitter_username": tweet.user.screen_name })
    resp.attributes
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    User.db
  end
end