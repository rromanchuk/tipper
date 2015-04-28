class User
  TABLE_NAME = "TipperBitcoinAccounts"
  
  def self.all
    @resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.find(twitter_id)
    puts "User#find #{twitter_id}"
      db.get_item(
        table_name: TABLE_NAME,
        key: {
          "TwitterUserID" => twitter_id,
        },
      ).item
  end

  def self.create_user(twitter_id, twitter_username, isActive=false)

    attributes = {
        "BitcoinAddress" => {
          value: B.getNewUserAddress
        },
        "TwitterUsername" => {
          value: twitter_username
        },
        "token" => {
          value: SecureRandom.urlsafe_base64(30)
        }
      }

    if isActive
      attributes["IsActive"] = { value: "X" }
    end

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "TwitterUserID" => twitter_id,
      },
      attribute_updates: attributes,
      return_values: "ALL_NEW"
    )
    resp.attributes
  end


  def self.update_user(twitter_id, attribute_updates)
    resp = db.update_item(
      table_name: TABLE_NAME,
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