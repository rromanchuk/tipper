#require 'bitcon_client'
class B

  # http://bitcoindenominations.org/
  TIP_AMOUNT = 0.0005  # 12/cents
  FEE_AMOUNT = 0.00001
  STANDARD_FEE_AMOUNT = 0.0001
  FUND_AMOUNT = 0.02

  def self.client
    @client ||= BitcoinClient::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"], {:host => ENV["RPC_HOST"], port: ENV["RPC_PORT"], :ssl => ENV["RPC_SHOULD_USE_SSL"] })
  end

  def self.fund_amount_ubtc
    (TIP_AMOUNT/0.00000100).to_i
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

  def self.withdraw(fromAddress, toAddress)
    Rails.logger.info "tip_user from #{fromAddress} -> #{toAddress}"
    if fromAddress == toAddress
      Rails.logger.info "Trying to tip yourself.... "
      return nil
    end

    # Get the total avail inputs from the snders address with at least 1 confirmation
    unspents = client.listunspent(0, 9999999, [fromAddress])
    Rails.logger.info "unspents: #{unspents}"

    # Sum all of the amounts
    amounts_array = unspents.map {|a| a["amount"] }
    Rails.logger.info "amounts_array: #{amounts_array}"
    senderBTCBalance = amounts_array.inject(:+)
    Rails.logger.info "senderBTCBalance: #{senderBTCBalance}"
    unless senderBTCBalance
      return nil
    end

    # Transaction fees
    numInputs = unspents.length
    bytes = 148 * numInputs + 34 * 2 + 10
    transaction_fee = (bytes / 1000) * STANDARD_FEE_AMOUNT
    Rails.logger.info "transaction_fee: #{transaction_fee}"
    transaction_fee = [STANDARD_FEE_AMOUNT, transaction_fee].max
    Rails.logger.info "numInputs: #{numInputs}, bytes: #{bytes}, transaction_fee: #{transaction_fee}"

    amount_to_send = senderBTCBalance - transaction_fee
    Rails.logger.info "amount_to_send: #{amount_to_send}, senderBTCBalance: #{senderBTCBalance}, transaction_fee: #{transaction_fee}"

    # Generate the transaction
    rawtx = client.createrawtransaction(unspents, {toAddress => amount_to_send})
    Rails.logger.info "rawtx:#{rawtx}"

    # Sign the transaction
    signedTx = client.signrawtransaction(rawtx, unspents)
    Rails.logger.info "signedTx: #{signedTx}"

    # Broadcast transaction on the network
    return client.sendrawtransaction(signedTx["hex"])
  end

  def self.tip_user(fromAddress, toAddress)
    Rails.logger.info "tip_user from #{fromAddress} -> #{toAddress}"
    if fromAddress == toAddress
      Rails.logger.info "Trying to tip yourself.... "
      return nil
    end
    # Get the total avail inputs from the snders address with at least 1 confirmation
    unspents = client.listunspent(0, 9999999, [fromAddress])
    Rails.logger.info "unspents: #{unspents}"

    # Sum all of the amounts
    amounts_array = unspents.map {|a| a["amount"] }
    Rails.logger.info "amounts_array: #{amounts_array}"
    senderBTCBalance = amounts_array.inject(:+)
    Rails.logger.info "senderBTCBalance: #{senderBTCBalance}"
    unless senderBTCBalance
      return nil
    end

    # Transaction fees
    numInputs = unspents.length
    bytes = 148 * numInputs + 34 * 2 + 10
    transaction_fee = (bytes / 1000) * 0.0001
    Rails.logger.info "transaction_fee: #{transaction_fee}"
    transaction_fee = FEE_AMOUNT
    Rails.logger.info "numInputs: #{numInputs}, bytes: #{bytes}, transaction_fee: #{transaction_fee}"

    # The amount of btc to send to the receiving user
    amount_to_send_to_other_user = TIP_AMOUNT

    # Does the user have enough money? 
    if senderBTCBalance < (transaction_fee + amount_to_send_to_other_user)
      Rails.logger.info "User does not have a large enough balance to perform this transaction"
      return nil
    end

    # Calculate the amount that needs to be sent back to the sender after using avail inputs
    amount_to_send_back_to_self = senderBTCBalance - amount_to_send_to_other_user - transaction_fee
    Rails.logger.info "senderBTCBalance: #{senderBTCBalance}, amount_to_send_back_to_self: #{amount_to_send_back_to_self}, amount_to_send_to_other_user: #{amount_to_send_to_other_user}, transaction_fee: #{transaction_fee}"

    # Generate the transaction
    rawtx = client.createrawtransaction(unspents, {fromAddress=>amount_to_send_back_to_self, toAddress => amount_to_send_to_other_user})
    Rails.logger.info "rawtx:#{rawtx}"

    # Sign the transaction
    signedTx = client.signrawtransaction(rawtx, unspents)
    Rails.logger.info "signedTx: #{signedTx}"

    # Broadcast transaction on the network
    return client.sendrawtransaction(signedTx["hex"])
  end

  def self.recent
    client.listtransactions("*", 100)
  end

  def self.fundUser(address)
    client.sendfrom("rromanchuk", address, FUND_AMOUNT)
  end

end
