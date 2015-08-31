class Settings
  include EmberModel

  TABLE_NAME = "TipperSettings"

  def initialize(settings_from_dynamo={})
    @id = settings_from_dynamo["Version"]
    @version = settings_from_dynamo["Version"]
    @fee_amount = settings_from_dynamo["FeeAmount"]
    @fund_amount = settings_from_dynamo["FundAmount"]
    @tip_amount = settings_from_dynamo["TipAmount"]
    @tip_amount = settings_from_dynamo["TipAmount"]
    # FIXME
    @market_price = JSON.parse(open("https://api.coinbase.com/v1/prices/buy.json?qty=#{@fund_amount}").read)["amount"]
  end

  def self.find(version)
    db.get_item(
      table_name: TABLE_NAME,
      key: {
        "Version" => version,
      },
    ).item
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    Settings.db
  end

end