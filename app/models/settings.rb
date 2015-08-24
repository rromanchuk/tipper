class Settings
  include EmberModel

  TABLE_NAME = "TipperSettings"

  def initialize(settings_from_dynamo={})
    @id = settings_from_dynamo["Version"]
    @version = settings_from_dynamo["Version"]
    @fee_amount = settings_from_dynamo["FeeAmount"]
    @fund_amount = settings_from_dynamo["FundAmount"]
    @tip_amount = settings_from_dynamo["TipAmount"]
  end

  def self.find(version)
    db.get_item(
      table_name: TABLE_NAME,
      key: {
        "Version" => version,
      },
    ).item
  end

end