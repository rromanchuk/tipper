class Transaction
  TABLE_NAME = "TipperBitcoinTransactions"

  def self.create(txid)
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
        "details" => {
          value: transaction["details"].to_json
        }
      }

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "txid" => txid,
      },
      attribute_updates: attributes,
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

  def self.create_wallet_transaction(txid)
    transaction = B.client.gettransaction(txid)

    putRequests = []
    transaction["details"].each do |tx|
      putRequests << { put_request:
        { item:
          { "account": tx["account"],
            "category": tx["category"],
            "amount": tx["amount"],
            "vout": tx["vout"],
            "TransactionID": txid,
            "BitcoinAddress": tx["address"],
          } 
        } 
      }
    end

    resp = db.batch_write_item(
      # required
      request_items: {
        "TipperWalletTransaction" => putRequests
      },
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