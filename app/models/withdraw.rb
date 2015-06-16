class Withdraw
  TABLE_NAME = "TipperWithdrawTransaction"

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
    attributes = {
        "TwitterUsername" => {
          value: fromUser["TwitterUsername"]
        },
        "amount" => {
          value: transaction["amount"]
        },
        "fee" => {
          value: transaction["fee"]
        },
        "time" => {
          value: transaction["time"]
        },
        "confirmations" => {
          value: transaction["confirmations"]
        },
        "toBitcoinAddress" => {
          value: toBitcoinAddress
        },
        "details" => {
          value: transaction["details"].to_json
        },
        "TwitterID" => {
          value: fromUser["TwitterUserID"]
        }
      }

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "UserID" => fromUser["UserID"],
        "TransactionID" => txid
      },
      attribute_updates: attributes,
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

end