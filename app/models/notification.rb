class Notification
  include EmberModel
  TABLE_NAME = "TipperNotifications"
  #TYPES = {:transaction_confirmed: }


  UPDATE_EXPRESSION = "SET " +
                      "NotificationText = :text, " +
                      "NotificationType = :notification_type, " +
                      "CreatedAt        = :created_at, " +
                      "UserID           = :user_id, " +
                      "TipID            = :tip_id, " +
                      "TipFromUserID    = :tip_from_user_id"

  PROBLEM_EXPRESSION = "SET " +
                      "NotificationText = :text, " +
                      "NotificationType = :notification_type, " +
                      "CreatedAt        = :created_at, " +
                      "UserID           = :user_id " +

  def self.create(user_id, type, text, favorite={})
    resp = db.update_item(
        # required
        table_name: Notification::TABLE_NAME,
        # required
        key: {
          "ObjectID" => SecureRandom.uuid
        },
        update_expression: UPDATE_EXPRESSION,
        expression_attribute_values: {":text": text, ":notification_type": type, ":created_at": Time.now.to_i, ":user_id": user_id, ":tip_id": favorite["ObjectID"], ":tip_from_user_id": favorite["FromUserID"]},
        return_values: "ALL_NEW")

    resp.attributes
  end

  def self.create_problem(user_id, type, text)
    resp = db.update_item(
        # required
        table_name: Notification::TABLE_NAME,
        # required
        key: {
          "ObjectID" => SecureRandom.uuid
        },
        update_expression: PROBLEM_EXPRESSION,
        expression_attribute_values: {":text": text, ":notification_type": type, ":created_at": Time.now.to_i, ":user_id": user_id},
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