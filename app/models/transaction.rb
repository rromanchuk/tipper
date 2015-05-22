class Transaction
  TABLE_NAME = "TipperBitcoinTransactions"

  def self.create(transaction, fromUser=nil, toUser=nil)
    attributes = {
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
        "details" => {
          value: transaction["details"].to_json
        }
      }

    if fromUser
      attributes["FromTwitterID"] = {value: fromUser["TwitterUserID"]}
      attributes["FromTwitterUsername"] = {value: fromUser["TwitterUsername"]}
      attributes["FromBitcoinAddress"] = { value: fromUser["BitcoinAddress"]}
    end

    if toUser
      attributes["ToTwitterID"] = {value: toUser["TwitterUserID"] }
      attributes["ToTwitterUsername"] = { value: toUser["TwitterUsername"] }
      attributes["ToBitcoinAddress"] = { value: toUser["BitcoinAddress"] }
    end

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "txid" => transaction["txid"],
      },
      attribute_updates: attributes,
      return_values: "ALL_NEW"
    )

    resp.attributes
  end


  def self.all
    resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    Transaction.db
  end

end