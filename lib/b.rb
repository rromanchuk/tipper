#require 'bitcon_client'
class B
  def self.client
    @client ||= Bitcoin::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"], {:host => ENV["RPC_HOST"], port: ENV["RPC_PORT"], :ssl => ENV["RPC_SHOULD_USE_SSL"] })
  end

  def self.totalBalance
    s = Satoshi.new(client.balance)
    {satoshi: s.to_i, mbtc: s.to_mbtc, btc: s.to_btc}
  end

  def self.balance(address)
    balance = client.getreceivedbyaddress(address)
    s = Satoshi.new(balance)
    {satoshi: s.to_i, mbtc: s.to_mbtc, btc: s.to_btc}
  end

  def self.getNewUserAddress
    client.getnewaddress("tipper_users")
  end

  def self.tipUser(fromAccount, toAccount, amount)
    client.move(fromAccount, toAccount, amount)
  end

  def self.recent
    client.listtransactions("*", 20)
  end

  def self.fundUser(address)
    client.sendfrom("rromanchuk", address, 0.0002)
  end

end