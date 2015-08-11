class Favorite

  def self.batchWrite(collection, currentUser)
    putRequests = []
    collection.each do |tweet|
      Rails.logger.info "Favorite#batchWrite updating favorite object..."
      update_favorite(tweet, currentUser)
    end
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
      update_expression: Tip::UPDATE_EXPRESSION,
      expression_attribute_values: {":provider": "twitter",
                                    ":tweet_id": tweet.id.to_s,
                                    ":tweet_json": tweet.to_json,
                                    ":created_at": tweet.created_at.to_i,
                                    ":from_twitter_username": currentUser["TwitterUsername"],
                                    ":from_twitter_profile_image":  ? currentUser["ProfileImage"] : "https://a0.twimg.com/sticky/default_profile_images/default_profile_6_normal.png",
                                    ":from_twitter_id": currentUser["TwitterUserID"],
                                    ":to_twitter_id": tweet.user.id.to_s,
                                    ":to_twitter_profile_image": tweet.user.profile_image_url.to_s,
                                    ":to_twitter_username": tweet.user.screen_name ? tweet.user.screen_name : "https://a0.twimg.com/sticky/default_profile_images/default_profile_6_normal.png"
                                    })
    resp.attributes
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    User.db
  end
end