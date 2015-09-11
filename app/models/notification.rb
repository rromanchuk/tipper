class Notification
  include EmberModel
  TABLE_NAME = "TipperNotifications"


  UPDATE_EXPRESSION = "SET " +
                      "UserID = :user_id, " +
                      "TwitterAuthToken = :twitter_auth_token, " +
                      "TwitterAuthSecret = :twitter_auth_secret, " +
                      "ProfileImage = :profile_image, " +
                      "TwitterUserID = :twitter_user_id, " +
                      "TwitterUsername = :twitter_username"


  def self.create(user, type)
    resp = db.update_item(
        # required
        table_name: Notification::TABLE_NAME,
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

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    Notification.db
  end


end