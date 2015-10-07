class User
  include EmberModel

  attr_accessor :user_id, :bitcoin_address, :twitter_user_id, :twitter_username, :profile_image

  TABLE_NAME = "TipperUsers"
  TIPPER_BOT_USER_ID = "98c95beb-0238-425e-b644-317efb4b22a9"
  DEFAULT_PHOTO = "https://abs.twimg.com/sticky/default_profile_images/default_profile_6_normal.png"
  # Secondary indexes
  INDEX_BITCOIN_ADDRESS = "BitcoinAddress-index"
  INDEX_IS_ACTIVE = "IsActive-CreatedAt-index"
  INDEX_TWITTER_TOKEN = "TwitterAuthToken-index"
  INDEX_TWITTER_USERID = "TwitterUserID-index"

  # Update expressions
  UPDATE_BALANCE_EXPRESSION = "SET " +
                              "BitcoinBalanceBTC = :bitcoin_balance_btc"


  UPDATE_COGNITO_EXPRESSION = "SET " +
                      "CognitoToken = :cognito_token, " +
                      "CognitoIdentity = :cognito_identity"

  UPDATE_EXPRESSION = "SET " +
                      "IsActive = :is_active, " +
                      "TwitterAuthToken = :twitter_auth_token, " +
                      "TwitterAuthSecret = :twitter_auth_secret, " +
                      "ProfileImage = :profile_image, " +
                      "TwitterUserID = :twitter_user_id, " +
                      "TwitterUsername = :twitter_username"

  UPDATE_NEW_USER_EXPRESSION = UPDATE_EXPRESSION + ", " +
                      "CreatedAt = :created_at, " +
                      "#T = :token, " +
                      "BitcoinAddress = :bitcoin_address" 

  UPDATE_STUB_USER_EXPRESSION = "SET " +
                                "#T = :token, " +
                                "CreatedAt = :created_at, " +
                                "BitcoinAddress = :bitcoin_address, " +
                                "TwitterUserID = :twitter_user_id, " +
                                "ProfileImage = :profile_image, " +
                                "TwitterUsername = :twitter_username"

  REMOVE_EXPIRED_ARNS = "DELETE " +
                        "EndpointArns :endpoint_arns"

  RESERVED_ATTRIBUTES = {"#T": "token"}

  def initialize(user_from_dynamo={})
    @id = user_from_dynamo["UserID"]
    @bitcoin_address = user_from_dynamo["BitcoinAddress"]
    @twitter_user_id = user_from_dynamo["TwitterUserID"]
    @twitter_username = user_from_dynamo["TwitterUsername"]
    @profile_image = user_from_dynamo["ProfileImage"]
    @user_id = user_from_dynamo["UserID"]
    @bitcoin_balance_btc = user_from_dynamo["BitcoinBalanceBTC"]
  end

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
      index_name: INDEX_IS_ACTIVE,
      scan_index_forward: false,
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

  def self.find(user_id)
    db.get_item(
      table_name: TABLE_NAME,
      key: {
        "UserID" => user_id,
      },
    ).item
  end

  def self.update(user_id, update_expression, update_values, expression_attribute_names=nil)
    resp = db.update_item(
        # required
        table_name: User::TABLE_NAME,
        # required
        key: {
          "UserID" => user_id,
        },
        update_expression: update_expression,
        expression_attribute_names: expression_attribute_names,
        expression_attribute_values: update_values,
        return_values: "ALL_NEW")

    resp.attributes
  end

  def self.find_by_twitter_id(twitter_id)
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: INDEX_TWITTER_USERID,
      key_conditions: {
        "TwitterUserID" => {
          attribute_value_list: [
            twitter_id, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          ],
        # required
          comparison_operator: "EQ",
        },
      },
    ).items.first
  end

  def self.find_by_twitter_token(twitter_token)
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: INDEX_TWITTER_TOKEN,
      key_conditions: {
        "TwitterAuthToken" => {
          attribute_value_list: [
            twitter_token, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          ],
        # required
          comparison_operator: "EQ",
        },
      },
    ).items.first
  end

  def self.find_by_address(address)
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: INDEX_BITCOIN_ADDRESS,
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

  def self.delete_endpoint_arns(user_id, arns=[])
    resp = db.update_item(
        # required
        table_name: User::TABLE_NAME,
        # required
        key: {
          "UserID" => user_id,
        },
        update_expression: REMOVE_EXPIRED_ARNS,
        expression_attribute_values: {":endpoint_arns": arns.to_set  },
        return_values: "ALL_NEW")
    resp.attributes
  end

  # Flag setters
  def self.deep_crawl_started(user)
    self.update(user["UserID"], "SET TwittterDeepCrawledAt = :twitter_deep_crawled_at", {":twitter_deep_crawled_at": Time.now.to_i})
  end

  def self.turn_off_automatic_tipping(user)
    self.update(user["UserID"], "SET AutomaticTippingEnabled = :automatic_tipping_enabled", {":automatic_tipping_enabled": false})
  end

  def self.turn_on_automatic_tipping(user)
    self.update(user["UserID"], "SET AutomaticTippingEnabled = :automatic_tipping_enabled", {":automatic_tipping_enabled": true})
  end

  def self.tipped_from_us(user)
    self.update(user["UserID"], "SET TippedFromUsAt = :tipped_from_us_at", {":tipped_from_us_at": Time.now.to_i})
  end

  def self.find_tipper_bot
    User.find(TIPPER_BOT_USER_ID)
  end

  def self.create_user(additional_attributes={})
    new_user_id = SecureRandom.uuid
    attributes = {":token": SecureRandom.urlsafe_base64(30), ":bitcoin_address": B.getNewUserAddress, ":created_at": Time.now.to_i }
    attributes = attributes.merge(additional_attributes)
    
    user = User.update(new_user_id, UPDATE_NEW_USER_EXPRESSION, attributes, RESERVED_ATTRIBUTES)
    NotifyAdmin.new_user(user["TwitterUsername"])
    user
  end

  def self.create_stub_user(additional_attributes={})
    new_user_id = SecureRandom.uuid
    attributes = {":token": SecureRandom.urlsafe_base64(30), ":bitcoin_address": B.getNewUserAddress, ":created_at": Time.now.to_i }
    attributes = attributes.merge(additional_attributes)
    user = User.update(new_user_id, UPDATE_STUB_USER_EXPRESSION, attributes, RESERVED_ATTRIBUTES)
    NotifyAdmin.new_stub_user(user["TwitterUsername"])
    user
  end

  def self.update_balance_by_address(address)
    user = User.find_by_address(address)
    User.update_balance(user) if user
    user
  end

  def self.update_balance(user)
    balance = B.balance(user["BitcoinAddress"])
    attributes = {":bitcoin_balance_btc": balance[:btc]}
    Rails.logger.info "balance is #{balance} bitcoinaddress is #{user["BitcoinAddress"]}"
    User.update(user["UserID"], UPDATE_BALANCE_EXPRESSION, attributes)
  end

  def self.client_for_user(user)
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = user["TwitterAuthToken"]
      config.access_token_secret = user["TwitterAuthSecret"]
    end
  end

  def self.client_for_app
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    end
  end

  def self.update_user_with_twitter(user, is_stub=false)
    begin
      client = is_stub ? User.client_for_app : User.client_for_user(user)
      twitter_user = client.user(screenname: user["TwitterUsername"], include_entities: false)
      puts twitter_user.profile_image_url_https.to_s
      attributes = {":profile_image": twitter_user.profile_image_url_https.to_s, ":twitter_username": twitter_user.screen_name}
      User.update(user["UserID"], "SET ProfileImage = :profile_image, TwitterUsername = :twitter_username", attributes)
    rescue => e
      raise e
      Rails.logger.error "User::update_user_with_twitter failed"
    end
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