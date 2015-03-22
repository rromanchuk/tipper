class User

  # def self.updateCognitoSync()
  #     resp = cognitosync.update_records(
  #       # required
  #       identity_pool_id: "IdentityPoolId",
  #       # required
  #       identity_id: "IdentityId",
  #       dataset_name: "Profile",
  #       device_id: "DeviceId",
  #       record_patches: [
  #         {
  #           # required
  #           op: "replace",
  #           # required
  #           key: "RecordKey",
  #           value: "RecordValue",
  #           # required
  #           sync_count: 1,
  #           device_last_modified_date: Time.now,
  #         },
  #       ],
  #       # required
  #       sync_session_token: "SyncSessionToken",
  #       client_context: "ClientContext",
  #   )
  # end

  def self.all
    @resp = db.scan(
      # required
      table_name: "TipperBitcoinAccounts",
    )
  end

  def self.syncBalance(twitter_id)
    user = User.find()
  end

  def self.find(twitter_id)
      db.get_item(
        table_name: "TipperBitcoinAccounts",
        key: {
          "TwitterUserID" => twitter_id,
        },
      ).item
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