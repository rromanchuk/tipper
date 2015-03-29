class Tip
  
  def self.new_tip(tweetId, from, to, txid)
    puts "new_tip tweetId:#{tweetId}, from:#{from}, to:#{to}, txid:#{txid}"
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
        }
        "CreatedAt" => {
          value: tweet.created_at.to_i
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