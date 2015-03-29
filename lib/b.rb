#require 'bitcon_client'
class B
  def self.client
    @client ||= BitcoinClient::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"], {:host => ENV["RPC_HOST"], port: ENV["RPC_PORT"], :ssl => ENV["RPC_SHOULD_USE_SSL"] })
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

  def self.unspent(address)
    client.listunspent(1, 99999, [address])
  end

  def self.tip_user(fromAddress, toAddress)
    unspents = client.listunspent(1, 9999999, [fromAddress])
    puts "unspents: #{unspents}"
    amounts_array = unspents.map {|a| a["amount"] }
    puts "amounts_array: #{amounts_array}"
    senderBTCBalance = amounts_array.inject(:+)
    puts "senderBTCBalance: #{senderBTCBalance}"
    amount_to_send_to_other_user = 0.001
    transaction_fee = 0.0001
    amount_to_send_back_to_self = senderBTCBalance - amount_to_send_to_other_user - transaction_fee

    rawtx = client.createrawtransaction(unspents, {fromAddress=>amount_to_send_back_to_self, toAddress => amount_to_send_to_other_user})
    puts "rawtx:#{rawtx}"
    signedTx = client.signrawtransaction(rawtx, unspents)
    puts "signedTx: #{signedTx}"
    return client.sendrawtransaction(signedTx["hex"])
  end

  def self.recent
    client.listtransactions("*", 20)
  end

  def self.fundUser(address)
    client.sendfrom("rromanchuk", address, 0.02)
  end

end
