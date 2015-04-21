class Tip
  
  def self.all
    @resp = db.scan(
      # required
      table_name: "TipperTips",
    )
  end
  def self.new_tip(tweet, fromUser, toUser, txid)
    puts "new_tip tweetId:#{tweetId}, from:#{from}, to:#{to}, txid:#{txid}"
    resp = db.update_item(
      table_name: "TipperTwitterFavorites",
      key: {
        "TweetID" => tweet.id.to_s,
      },
      attribute_updates: {
        "TipperUserID" => {
          value: fromUser["TwitterUserID"]
        },
        "ToTwitterID": {
          value: toUser["TwitterUserID"]
        },
        "FromTwitterID": {
          value: fromUser["TwitterUserID"]
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
          value: true
        }
      },
    )

    resp = db.update_item(
      table_name: "TipperTips",
      key: {
        "TweetID" => tweetId,
      },
      attribute_updates: {
        "ToTwitterID" => {
          value: to
        },
        "FromTwitterID" => {
          value: from
        },
        "txid" => {
          value: txid
        },
        "CreatedAt" => {
          value: Time.now.to_i
        },
        "TweetJSON" => {
          value: tweetJSON
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