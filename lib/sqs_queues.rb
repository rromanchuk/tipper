class SQSQueues
  def self.fetch_favorites
    "https://sqs.us-east-1.amazonaws.com/080383581145/FetchFavorites"
  end

  def self.new_tip
    "https://sqs.us-east-1.amazonaws.com/080383581145/TipperNewTip"
  end

  def self.wallet_notify
    "https://sqs.us-east-1.amazonaws.com/080383581145/WalletNotify"
  end
end