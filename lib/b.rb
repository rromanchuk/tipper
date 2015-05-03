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
    amounts_array = unspent(address).map {|a| a["amount"] }
    balance = amounts_array.inject(:+)
    s = Satoshi.new(balance)
    {satoshi: s.to_i, mbtc: s.to_mbtc, btc: s.to_btc}
  end

  def self.getNewUserAddress
    client.getnewaddress("tipper_users")
  end

  def self.unspent(address)
    client.listunspent(0, 99999, [address])
  end

  def self.tip_user(fromAddress, toAddress)
    puts "tip_user from #{fromAddress} -> #{toAddress}"
    # Get the total avail inputs from the snders address with at least 1 confirmation
    unspents = client.listunspent(0, 9999999, [fromAddress])
    puts "unspents: #{unspents}"

    # Sum all of the amounts
    amounts_array = unspents.map {|a| a["amount"] }
    puts "amounts_array: #{amounts_array}"
    senderBTCBalance = amounts_array.inject(:+)
    puts "senderBTCBalance: #{senderBTCBalance}"
    unless senderBTCBalance
      return nil
    end

    # Transaction fees
    numInputs = unspents.length
    bytes = (numInputs * 148) + (2 * 34)
    transaction_fee = (bytes / 1000) * 0.0001
    puts "numInputs: #{numInputs}, bytes: #{bytes}, transaction_fee: #{transaction_fee}"

    # The amount of btc to send to the receiving user
    amount_to_send_to_other_user = 0.001

    # Does the user have enough money? 
    if senderBTCBalance < (transaction_fee + amount_to_send_to_other_user)
      puts "User does not have a large enough balance to perform this transaction"
      return nil
    end

    # Calculate the amount that needs to be sent back to the sender after using avail inputs
    amount_to_send_back_to_self = senderBTCBalance - amount_to_send_to_other_user - transaction_fee

    # Generate the transaction
    rawtx = client.createrawtransaction(unspents, {fromAddress=>amount_to_send_back_to_self, toAddress => amount_to_send_to_other_user})
    puts "rawtx:#{rawtx}"

    # Sign the transaction
    signedTx = client.signrawtransaction(rawtx, unspents)
    puts "signedTx: #{signedTx}"

    # Broadcast transaction on the network
    return client.sendrawtransaction(signedTx["hex"])
  end

  def self.recent
    client.listtransactions("*", 100)
  end

  def self.fundUser(address)
    client.sendfrom("rromanchuk", address, 0.02)
  end

end
