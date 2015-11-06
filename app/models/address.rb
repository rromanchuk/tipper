class Address
  TABLE_NAME = "TipperBitcoinAddress"

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end
  
  def db
    Address.db
  end

  def self.all
    @resp = db.scan(
      # required
      table_name: TABLE_NAME,
    )
  end

  def self.generate_address_pool
    (1..5).each do 
      Address.create
    end
  end

  def self.delete(address)
    resp = db.delete_item(
      table_name: TABLE_NAME,
      key: {
        "BitcoinAddress" => address
      }
    )
    resp.attributes
  end

  def self.create
    address = B.getNewUserAddress
    resp = db.update_item(
      table_name: TABLE_NAME,
      key: {
        "BitcoinAddress" => address
      },
      return_values: "ALL_NEW"
    )
    resp.attributes
  end

end