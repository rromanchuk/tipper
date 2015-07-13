class Withdraw
  TABLE_NAME = "TipperWithdrawTransaction"

  UPDATE_EXPRESSION = "SET " +
                      "TwitterUsername = :twitter_username, " +
                      "amount = :amount, " +
                      "fee = :fee, " +
                      "#T = :time, " +
                      "confirmations = :confirmations, " +
                      "toBitcoinAddress = :to_bitcoin_address, " +
                      "details = :details, " +
                      "TwitterID = :tweet_id"

  RESERVED_ATTRIBUTES = {"#T": "time"}

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    Withdraw.db
  end

  def self.all
    @resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.create(fromUser, toBitcoinAddress, txid)
    transaction = B.client.gettransaction(txid)
    attribute_values = {":twitter_username": fromUser["TwitterUsername"],
                        ":amount": transaction["amount"],
                        ":fee": transaction["fee"],
                        ":time": transaction["time"],
                        ":confirmations": transaction["confirmations"],
                        ":to_bitcoin_address": toBitcoinAddress,
                        ":details": transaction["details"].to_json,
                        ":twitter_id": fromUser["TwitterUserID"]}
    # attributes = {
    #     "TwitterUsername" => {
    #       value: fromUser["TwitterUsername"]
    #     },
    #     "amount" => {
    #       value: transaction["amount"]
    #     },
    #     "fee" => {
    #       value: transaction["fee"]
    #     },
    #     "time" => {
    #       value: transaction["time"]
    #     },
    #     "confirmations" => {
    #       value: transaction["confirmations"]
    #     },
    #     "toBitcoinAddress" => {
    #       value: toBitcoinAddress
    #     },
    #     "details" => {
    #       value: transaction["details"].to_json
    #     },
    #     "TwitterID" => {
    #       value: fromUser["TwitterUserID"]
    #     }
    #   }

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "UserID" => fromUser["UserID"],
        "TransactionID" => txid
      },
      update_expression: UPDATE_EXPRESSION,
      expression_attribute_names: RESERVED_ATTRIBUTES,
      expression_attribute_values: attribute_values,
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

end