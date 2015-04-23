class Tip
  
  def self.all
    @resp = db.scan(
      # required
      table_name: "TipperTwitterFavoritesTest",
    )
  end

  def self.new_tip(tweet, fromUser, toUser, txid)
    puts "new_tip tweetId:#{tweet.id.to_s}, from:#{fromUser["TwitterUsername"]}, to:#{toUser["TwitterUsername"]}, txid:#{txid}"
    resp = db.update_item(
      table_name: "TipperTwitterFavoritesTest",
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
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def db
    Tip.db
  end

end