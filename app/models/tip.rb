class Tip
  include EmberModel

  TABLE_NAME = "TipperTips"
  TXID_INDEX = "txid-TippedAt-index"

  UPDATE_EXPRESSION = "SET " +
                              "Provider = :provider, " +
                              "TweetID = :tweet_id, " +
                              "CreatedAt = :created_at, " +
                              "FromTwitterUsername = :from_twitter_username, " +
                              "FromTwitterProfileImage = :from_twitter_profile_image, " +
                              "FromTwitterID = :from_twitter_id, " + # deprecated
                              "ToTwitterID = :to_twitter_id, " + # deprecated
                              "ToTwitterUsername = :to_twitter_username, " +
                              "ToTwitterProfileImage = :to_twitter_profile_image"

  def initialize(tip_from_dynamo)
    @id                         = tip_from_dynamo["txid"]
    @txid                       = tip_from_dynamo["txid"]
    @from_twitter_id            = tip_from_dynamo["FromTwitterID"]
    @to_twitter_id              = tip_from_dynamo["ToTwitterID"]
    @from_twitter_username      = tip_from_dynamo["FromTwitterUsername"]
    @to_twitter_username        = tip_from_dynamo["ToTwitterUsername"]
    @to_twitter_profile_image   = tip_from_dynamo["ToTwitterProfileImage"]
    @from_twitter_profile_image = tip_from_dynamo["FromTwitterProfileImage"]
    @object_id                  = tip_from_dynamo["ObjectID"]
    @transaction                = tip_from_dynamo["txid"]
    @from_user                  = tip_from_dynamo["FromUserID"]
    @to_user                    = tip_from_dynamo["ToUserID"]
    @tipped_at                  = Time.at(tip_from_dynamo["TippedAt"]).to_datetime.iso8601
  end

  def self.all
    resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.active
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: "DidLeaveTip-TippedAt-index",
      scan_index_forward: false,
      key_condition_expression: "DidLeaveTip = :did_leave_tip AND TippedAt > :rangeval",
      expression_attribute_values: {":did_leave_tip": "X", ":rangeval": 0}
    )
  end

  def self.new_tip(tweet, fromUser, toUser, txid)
    Rails.logger.info "new_tip tweetId:#{tweet.id.to_s}, from:#{fromUser["TwitterUsername"]}, to:#{toUser["TwitterUsername"]}, txid:#{txid}"

    update_expression = UPDATE_EXPRESSION + ", DidLeaveTip = :did_leave_tip, txid = :txid, ToUserID = :to_user_id, TippedAt = :tipped_at"
    resp = db.update_item(
      # required
      table_name: Tip::TABLE_NAME,
      return_values: "ALL_NEW",
      # required
      key: {
        "ObjectID" =>  tweet.id.to_s,
        "FromUserID" => fromUser["UserID"],
      },
      update_expression: update_expression,
      expression_attribute_values: {":provider": "twitter",
                                    ":tweet_id": tweet.id.to_s,
                                    ":created_at": tweet.created_at.to_i,
                                    ":from_twitter_username": fromUser["TwitterUsername"],
                                    ":from_twitter_profile_image": fromUser["ProfileImage"] ? fromUser["ProfileImage"] : User::DEFAULT_PHOTO,
                                    ":from_twitter_id": fromUser["TwitterUserID"],
                                    ":to_twitter_profile_image": toUser["ProfileImage"] ? toUser["ProfileImage"] : User::DEFAULT_PHOTO,
                                    ":to_twitter_username": toUser["TwitterUsername"],
                                    ":to_user_id": toUser["UserID"],
                                    ":to_twitter_id": toUser["TwitterUserID"],
                                    ":did_leave_tip": "X",
                                    ":txid": txid,
                                    ":tipped_at": Time.now.to_i
                                   })

    User.update_balance(fromUser)
    User.update_balance(toUser)
    resp.attributes
  end


   def self.find(object_id, from_id)
    Rails.logger.info "User#find #{twitter_id}"
      db.get_item(
        table_name: TABLE_NAME,
        key: {
          "ObjectID" => object_id,
          "FromUserID" => from_id
        },
      ).item
  end

  def self.find_by_txid(txid)
    resp = db.query(
      # required
      table_name: TABLE_NAME,
      index_name: TXID_INDEX,
      key_conditions: {
        "txid" => {
          attribute_value_list: [
            txid, #<Hash,Array,String,Numeric,Boolean,nil,IO,Set>,
          ],
        # required
          comparison_operator: "EQ",
        },
      },
    ).items.first
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def db
    Tip.db
  end
end