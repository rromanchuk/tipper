class SqsQueues
  def self.fetch_favorites
    "https://sqs.us-east-1.amazonaws.com/080383581145/FetchFavorites"
  end

  def self.update_favorites
    "https://sqs.us-east-1.amazonaws.com/080383581145/UpdateFavorites"
  end

  def self.new_tip
    "https://sqs.us-east-1.amazonaws.com/080383581145/TipperNewTip"
  end

  def self.wallet_notify
    "https://sqs.us-east-1.amazonaws.com/080383581145/WalletNotify"
  end

  def self.withdraw_balance
    "https://sqs.us-east-1.amazonaws.com/080383581145/WithdrawBalance"
  end

  def self.fund
    "https://sqs.us-east-1.amazonaws.com/080383581145/TipperFund"
  end
end