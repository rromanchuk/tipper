class Withdraw
  TABLE_NAME = "TipperWithdraw"

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
    Transaction.create_wallet_transaction(txid)
    transaction = B.client.gettransaction(txid)
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
        "toBitcoinAddress" => {
          value: toBitcoinAddress
        }
        "details" => {
          value: transaction["details"].to_json
        }
      }

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "TwitterID" => fromUser["TwitterID"],
        "TransactionID" => txid
      },
      attribute_updates: attributes,
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

end