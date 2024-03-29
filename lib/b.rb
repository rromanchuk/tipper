#require 'bitcon_client'
class B

  FUND_FROM_ACCOUNT = "tipper_reserves"
  RESERVES_ADDRESS = ""
  TIPPERBOT_ADDRESS = ""
  NEW_USER_ACCOUNT = "tipper_users"

  # http://bitcoindenominations.org/
  TIP_AMOUNT = 0.0003  # 12/cents
  FEE_AMOUNT = 0.00001
  STANDARD_FEE_AMOUNT = 0.0001
  FUND_AMOUNT = 0.0135

  MTC_FRACTION = 0.00100000
  UTC_FRACTION = 0.00000100

  FUND_AMOUNT_UBTC = FUND_AMOUNT/UTC_FRACTION
  FUND_AMOUNT_MBTC = FUND_AMOUNT/MTC_FRACTION

  TIP_AMOUNT_UBTC = TIP_AMOUNT/UTC_FRACTION
  TIP_AMOUNT_MBTC = TIP_AMOUNT/MTC_FRACTION

  def self.client
    @client ||= BitcoinClient::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"], {:host => ENV["RPC_HOST"], port: ENV["RPC_PORT"], :ssl => ENV["RPC_SHOULD_USE_SSL"] })
  end

  def self.fund_amount_ubtc
    FUND_AMOUNT_UBTC.to_i
  end

  def self.totalBalance
    s = Satoshi.new(client.balance)
    {satoshi: s.to_i, mbtc: s.to_mbtc, btc: s.to_btc}
  end

  def self.balance(address)
    unspent_outputs = unspent(address)
    if unspent_outputs
      amounts_array = unspent_outputs.map {|a| a["amount"] }
      balance = amounts_array.inject(:+)
      s = Satoshi.new(balance)
      {satoshi: s.to_i, mbtc: s.to_mbtc, btc: s.to_btc}
    else
      {satoshi: 0, mbtc: 0, btc: 0}
    end
  end

  def self.getNewUserAddress
    client.getnewaddress(NEW_USER_ACCOUNT)
  end

  def self.unspent(address)
    begin
      client.listunspent(0, 99999, [address])
    rescue => e
      Rollbar.warning(e)
      nil
    end
  end

  def self.withdraw(fromAddress, toAddress)
    begin
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
    tx = client.sendrawtransaction(signedTx["hex"])

    rescue => e
      Rollbar.warning(e)
      tx = nil
    end

    tx
  end

  def self.tip_user(fromAddress, toAddress)
    begin
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
    tx = client.sendrawtransaction(signedTx["hex"])
    rescue => e
      Rollbar.warning(e)
      tx = nil
    end


    tx
  end

  def self.recent
    client.listtransactions("*", 100)
  end

  def self.fundUser(address)
    begin
      Rails.logger.info "fundUser from #{RESERVES_ADDRESS} -> #{address}"

      # Get the total avail inputs from the snders address with at least 1 confirmation
      unspents = client.listunspent(0, 9999999, [RESERVES_ADDRESS])
      Rails.logger.info "unspents: #{unspents}"

      # Sum all of the amounts
      amounts_array = unspents.map {|a| a["amount"] }
      Rails.logger.info "amounts_array: #{amounts_array}"
      senderBTCBalance = amounts_array.inject(:+)
      Rails.logger.info "senderBTCBalance: #{senderBTCBalance}"
      unless senderBTCBalance
        NotifyAdmin.reserves_depleted
        return nil
      end

      # Transaction fees, noop here, just for logging
      numInputs = unspents.length
      bytes = 148 * numInputs + 34 * 2 + 10
      transaction_fee = (bytes / 1000) * 0.0001
      Rails.logger.info "transaction_fee: #{transaction_fee}"


      transaction_fee = FEE_AMOUNT
      Rails.logger.info "numInputs: #{numInputs}, bytes: #{bytes}, transaction_fee: #{transaction_fee}"


      # The amount of btc to send to the receiving user
      amount_to_send_to_other_user = FUND_AMOUNT

      # Does the user have enough money? 
      if senderBTCBalance < (transaction_fee + amount_to_send_to_other_user)
        Rails.logger.info "User does not have a large enough balance to perform this transaction"
        NotifyAdmin.reserves_depleted
        return nil
      end

      # Calculate the amount that needs to be sent back to the sender after using avail inputs
      amount_to_send_back_to_self = senderBTCBalance - amount_to_send_to_other_user - transaction_fee
      Rails.logger.info "senderBTCBalance: #{senderBTCBalance}, amount_to_send_back_to_self: #{amount_to_send_back_to_self}, amount_to_send_to_other_user: #{amount_to_send_to_other_user}, transaction_fee: #{transaction_fee}"

      # Generate the transaction
      rawtx = client.createrawtransaction(unspents, {RESERVES_ADDRESS=>amount_to_send_back_to_self, address => amount_to_send_to_other_user})
      Rails.logger.info "rawtx:#{rawtx}"

      # Sign the transaction
      signedTx = client.signrawtransaction(rawtx, unspents)
      Rails.logger.info "signedTx: #{signedTx}"

      # Broadcast transaction on the network
      tx = client.sendrawtransaction(signedTx["hex"])
    rescue => e
      Rollbar.warning(e)
      tx = nil
    end
    tx
  end

end
