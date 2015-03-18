#require 'bitcon_client'
class B
  def self.client
    @client ||= Bitcoin::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"], {port: ENV["RPC_PORT"]})
  end

  def self.balance(address)
    balance = client.getreceivedbyaddress(address)
    s = Satoshi.new(balance)
    {satoshi: s.to_i, mbtc: s.to_mbtc, btc: s.to_btc}
  end

  def self.getNewUserAddress
    client.getaccountaddress("tipper_users")
  end

  def self.tipUser(fromAccount, toAccount, amount)
    client.move(fromAccount, toAccount, amount)
  end
end