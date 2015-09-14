class Notification
  include EmberModel
  TABLE_NAME = "TipperNotifications"
  #TYPES = {:transaction_confirmed: }


  UPDATE_EXPRESSION = "SET " +
                      "Type = :type, " +
                      "Text = :text, " +
                      "CreatedAt = :created_at " +


  def self.create(user_id, type, text)
    resp = db.update_item(
        # required
        table_name: Notification::TABLE_NAME,
        # required
        key: {
          "UserID" => user_id,
        },
        update_expression: UPDATE_EXPRESSION,
        expression_attribute_values: {":type": type, ":text": text, ":created_at": Time.now.to_i},
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