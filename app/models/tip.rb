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

  def self.batchWrite(collection, currentUser)
    putRequests = []
    collection.each do |tweet|
      putRequests << { put_request:
        { item:
          { "TweetID": tweet.id.to_s,
            "TweetJSON": tweet.to_json,
            "CreatedAt": tweet.created_at.to_i,
            "FromTwitterID": currentUser["TwitterUserID"],
            "FromTwitterUsername": currentUser["TwitterUsername"],
            "ToTwitterID": tweet.user.id.to_s,
            "ToTwitterUsername": tweet.user.screen_name
          }
        }
      }
    end
    resp = db.batch_write_item(
      # required
      request_items: {
        TABLE_NAME => putRequests
      },
    )
  end

  def self.new_tip(tweet, fromUser, toUser, txid)
    puts "new_tip tweetId:#{tweet.id.to_s}, from:#{fromUser["TwitterUsername"]}, to:#{toUser["TwitterUsername"]}, txid:#{txid}"
    resp = db.update_item(
      table_name: TABLE_NAME,
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
        "FromTwitterUsername": {
          value: fromUser["TwitterUsername"]
        },
        "txid" => {
          value: txid
        },
        "CreatedAt" => {
          value: Time.now.to_i
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
    puts "User#find #{twitter_id}"
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