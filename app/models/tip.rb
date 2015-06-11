class Tip
  TABLE_NAME = "TipperTwitterFavorites"

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
      index_name: "DidLeaveTip-index-copy",
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
        "TweetID" => tweet.id.to_s,
        "FromTwitterID" => fromUser["TwitterUserID"]
      },
      attribute_updates: {
        "ToTwitterID": {
          value: toUser["TwitterUserID"]
        },
        "ToTwitterUsername" => {
          value: toUser["TwitterUsername"]
        },
        "ToTwitterPofileImage" => {
          value: toUser["ProfileImage"]
        },
        "FromTwitterUsername": {
          value: fromUser["TwitterUsername"]
        },
        "FromTwitterPofileImage" => {
          value: fromUser["ProfileImage"]
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


   def self.find(tweet_id, from_id)
    Rails.logger.info "User#find #{twitter_id}"
      db.get_item(
        table_name: TABLE_NAME,
        key: {
          "TweetID" => tweet_id,
          "FromTwitterID" => from_id
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