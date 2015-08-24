
class Transaction
  include EmberModel

  TABLE_NAME = "TipperBitcoinTransactions"
  UPDATE_EXPRESSION = "SET " +
                      "amount = :amount, " +
                      "tip_amount = :tip_amount, " +
                      "fee = :fee, " +
                      "#T = :time, " +
                      "confirmations = :confirmations, " +
                      "category = :category, " +
                      "details = :details"

  RESERVED_ATTRIBUTES = {"#T": "time"}

  def initialize(transaction)
    @id                         = transaction["txid"]
    @amount                     = transaction["amount"]
    @details                    = transaction["details"]
    @fee                        = transaction["fee"]
    @txid                       = transaction["txid"]
    @tip_amount                 = transaction["tip_amount"]
    @confirmations              = transaction["confirmations"]
    @tip                        = transaction["txid"]
  end

  def self.create(transaction, fromUser=nil, toUser=nil)

    category = get_category_type(transaction)

    update_expression = UPDATE_EXPRESSION
    attribute_values = {":amount": transaction["amount"],
                        ":tip_amount": B::TIP_AMOUNT,
                        ":fee": transaction["fee"],
                        ":time": transaction["time"],
                        ":confirmations": transaction["confirmations"],
                        ":category": category,
                        ":details": transaction["details"].to_json}

    if fromUser
      update_expression = update_expression + ", FromUserID = :from_user_id, FromTwitterID = :from_twitter_id, FromTwitterUsername = :from_twitter_username, FromBitcoinAddress = :from_bitcoin_address"
      attribute_values = attribute_values.merge({":from_user_id": fromUser["UserID"], ":from_twitter_id": fromUser["TwitterUserID"], ":from_twitter_username": fromUser["TwitterUsername"], ":from_bitcoin_address": fromUser["BitcoinAddress"]})
    end

    if toUser
      update_expression = update_expression + ", ToUserID = :to_user_id, ToTwitterID = :to_twitter_id, ToTwitterUsername = :to_twitter_username, ToBitcoinAddress = :to_bitcoin_address"
      attribute_values = attribute_values.merge({":to_user_id": toUser["UserID"], ":to_twitter_id": toUser["TwitterUserID"], ":to_twitter_username": toUser["TwitterUsername"], ":to_bitcoin_address": toUser["BitcoinAddress"] })
    end

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "txid" => transaction["txid"],
      },
      return_values: "ALL_NEW", 
      update_expression: update_expression,
      expression_attribute_values: attribute_values,
      expression_attribute_names: RESERVED_ATTRIBUTES
    )

    resp.attributes
  end

  def self.update_transaction(txid)
    transaction = B.client.gettransaction(txid)
    attribute_values = {":amount": transaction["amount"],
                        ":tip_amount": B::TIP_AMOUNT,
                        ":fee": transaction["fee"],
                        ":time": transaction["time"],
                        ":confirmations": transaction["confirmations"],
                        ":category": get_category_type(transaction),
                        ":details": transaction["details"].to_json}

    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "txid" => txid,
      },
      return_values: "ALL_NEW", 
      update_expression: UPDATE_EXPRESSION,
      expression_attribute_values: attribute_values,
      expression_attribute_names: RESERVED_ATTRIBUTES
    )

    resp.attributes
  end

  def self.get_category_type(transaction)
    category = nil
    if transaction["amount"] == 0
      category = "internal_tip"
    elsif transaction["amount"] > 0
      category = "external_deposit"
    elsif transaction["amount"] < 0
      category = "external_withdrawal"
    end
    category
  end


  def self.all
    resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.find(txid)
    db.get_item(
      table_name: TABLE_NAME,
      key: {
        "txid" => txid,
      },
    ).item
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    Transaction.db
  end

end