class Transaction
  TABLE_NAME = "TipperBitcoinTransactions"

  def self.create(transaction)
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

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "txid" => transaction["txid"],
      },
      attribute_updates: attributes,
      return_values: "ALL_NEW"
    )

    transaction["details"].each do |tx|

    end

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