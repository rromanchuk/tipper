class User
  TABLE_NAME = "TipperBitcoinAccounts"
  
  def self.all
    @resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.find_active
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: "IsActive-index",
      key_conditions: {
        "IsActive" => {
          attribute_value_list: [
            "X", #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          ],
        # required
          comparison_operator: "EQ",
        },
      },
    )
  end

  def self.find(twitter_id)
    db.get_item(
      table_name: TABLE_NAME,
      key: {
        "TwitterUserID" => twitter_id,
      },
    ).item
  end

  def self.find_by_address(address)
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: "BitcoinAddress-index",
      key_conditions: {
        "BitcoinAddress" => {
          attribute_value_list: [
            address, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          ],
        # required
          comparison_operator: "EQ",
        },
      },
    ).items.first
  end

  def self.find_tipper_bot
    db.get_item(
      table_name: TABLE_NAME,
      key: {
        "TwitterUserID" => "3178504262",
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

  def self.update_balance_by_address(address)
    user = User.find_by_address(address)
    User.update_balance(user) if user
    user
  end

  def self.update_balance(user)
    balance = B.balance(user["BitcoinAddress"])
    Rails.logger.info "balance is #{balance} bitcoinaddress is #{user["BitcoinAddress"]}"

    resp = db.update_item(
      # required
      table_name: "TipperBitcoinAccounts",
      return_values: "ALL_NEW",
      # required
      key: {
        "TwitterUserID" => user["TwitterUserID"],
      },
      attribute_updates: {
        "BitcoinBalanceBTC" => {
          value: balance[:btc],
          action: "PUT",
        }
      })
    resp.attributes
  end

  def self.update_user_with_twitter(user)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = user["TwitterAuthToken"]
      config.access_token_secret = user["TwitterAuthSecret"]
    end

    twitter_user = client.user(user["TwitterUsername"])

    resp = db.update_item(
      # required
      table_name: "TipperBitcoinAccounts",
      return_values: "ALL_NEW",
      # required
      key: {
        "TwitterUserID" => user["TwitterUserID"],
      },
      attribute_updates: {
        "ProfileImage" => {
          value: twitter_user.profile_image_url,
          action: "PUT",
        },
        "Name" => {
          value: twitter_user.name,
          action: "PUT",
        }
      })
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

  def self.update_users
    users = User.find_active
    users.items.each do |user|
      User.update_user_with_twitter(user)
      sleep 1
    end
  end

end