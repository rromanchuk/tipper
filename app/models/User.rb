class User

  def self.createStubUser(twitter_id)
      resp = db.update_item(
      # required
      table_name: "TipperBitcoinAccounts",
      # required
      key: {
        "TwitterUserID" => twitter_id, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
        "BitcoinAddress" => B.getNewUserAddress
      },
      return_values: "NONE|ALL_OLD|UPDATED_OLD|ALL_NEW|UPDATED_NEW",
    )
  end

  def self.find(twitter_id)
      db.get_item(
        # required
        table_name: "TipperBitcoinAccounts",
        # required
        key: {
          "TwitterUserID" => twitter_id, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
        },
      )
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