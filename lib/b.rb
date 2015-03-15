#require 'bitcon_client'
class B
  def self.client
    @client ||= Bitcoin::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"], {port: 18333})
  end

  def self.balance(username)
    client.balance(username)
  end

  def self.addressForTwitterUsername(username)
    client.getaccountaddress(username)
  end

  def self.tipUser(fromAccount, toAccount, amount)
    client.move(fromAccount, toAccount, amount)
  end
end