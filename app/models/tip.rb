class Tip
  TABLE_NAME = "TipperTips"

  def self.all
    resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.active
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: "DidLeaveTip-index",
      key_conditions: {
        "DidLeaveTip" => {
          attribute_value_list: [
            "X", #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          ],
        # required
          comparison_operator: "EQ",
        },
      },
    )
  end

  def self.new_tip(tweet, fromUser, toUser, txid)
    Rails.logger.info "new_tip tweetId:#{tweet.id.to_s}, from:#{fromUser["TwitterUsername"]}, to:#{toUser["TwitterUsername"]}, txid:#{txid}"
    resp = db.update_item(
      table_name: TABLE_NAME,
      return_values: "ALL_NEW",
      key: {
        "ObjectID" => tweet.id.to_s,
        "FromUserID" => fromUser["UserID"]
      },
      attribute_updates: {
        "FromTwitterID": {
          value: fromUser["TwitterUserID"]
        },
        "ToTwitterID": {
          value: toUser["TwitterUserID"]
        },
        "ToTwitterUsername" => {
          value: toUser["TwitterUsername"]
        },
        "ToTwitterProfileImage" => {
          value: toUser["ProfileImage"]
        },
        "FromTwitterUsername": {
          value: fromUser["TwitterUsername"]
        },
        "FromTwitterProfileImage" => {
          value: fromUser["ProfileImage"] ? fromUser["ProfileImage"] : "https://a0.twimg.com/sticky/default_profile_images/default_profile_6_normal.png"
        },
        "txid" => {
          value: txid
        },
        "CreatedAt" => {
          value: tweet.created_at.to_i
        },
        "TweetJSON" => {
          value: tweet.to_json
        },
        "DidLeaveTip" => {
          value: "X"  # sparse index for nosql, X == true, nil == false
        }
      },
    )
    User.update_balance(fromUser)
    User.update_balance(toUser)
    resp.attributes
  end


   def self.find(object_id, from_id)
    Rails.logger.info "User#find #{twitter_id}"
      db.get_item(
        table_name: TABLE_NAME,
        key: {
          "ObjectID" => object_id,
          "FromUserID" => from_id
        },
      ).item
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def db
    Tip.db
  end

end