class Notification
  include EmberModel
  TABLE_NAME = "TipperNotifications"
  #TYPES = {:transaction_confirmed: }


  UPDATE_EXPRESSION = "SET " +
                      "NotificationText = :text, " +
                      "NotificationType = :notification_type"

  def self.create(user_id, type, text)
    resp = db.update_item(
        # required
        table_name: Notification::TABLE_NAME,
        # required
        key: {
          "UserID" => user_id,
          "CreatedAt" => Time.now.to_i
        },
        update_expression: UPDATE_EXPRESSION,
        expression_attribute_values: {":text": text, ":notification_type": type},
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