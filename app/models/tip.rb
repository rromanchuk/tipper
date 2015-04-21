class Tip
  
  def self.all
    @resp = db.scan(
      # required
      table_name: "TipperTwitterFavorites",
    )
  end
  def self.new_tip(tweet, fromUser, toUser, txid)
    puts "new_tip tweetId:#{tweet.id.to_s}, from:#{fromUser["TwitterUsername"]}, to:#{toUser["TwitterUsername"]}, txid:#{txid}"
    resp = db.update_item(
      table_name: "TipperTwitterFavorites",
      key: {
        "TweetID" => "#{fromUser["TwitterUserID"]}-#{tweet.id}",
      },
      attribute_updates: {
        "TipperUserID" => {
          value: fromUser["TwitterUserID"]
        },
        "ToTwitterID": {
          value: toUser["TwitterUserID"]
        },
        "ToTwitterUsername" => {
          value: toUser["TwitterUsername"]
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
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def db
    Tip.db
  end

end