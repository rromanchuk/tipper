class User

  def self.all
    @resp = db.scan(
      # required
      table_name: "TipperBitcoinAccounts",
    )
  end

  def self.find(twitter_id)
    puts "User#find #{twitter_id}"
      db.get_item(
        table_name: "TipperBitcoinAccounts",
        key: {
          "TwitterUserID" => twitter_id,
        },
      ).item
  end

  def self.create_user(twitter_id, twitter_username)
    resp = db.update_item(
      table_name: "TipperBitcoinAccounts",
      key: {
        "TwitterUserID" => twitter_id,
      },
      attribute_updates: {
        "BitcoinAddress" => {
          value: B.getNewUserAddress
        },
        "TwitterUsername" => {
          value: twitter_username
        }
      },
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

  def self.update_user(twitter_id, attribute_updates)
    resp = db.update_item(
      table_name: "TipperBitcoinAccounts",
      key: {
        "TwitterUserID" => twitter_id,
      },
      attribute_updates: attribute_updates,
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

  def self.userExists?(twitter_id)
    !find(twitter_id).item.nil?
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    User.db
  end

end