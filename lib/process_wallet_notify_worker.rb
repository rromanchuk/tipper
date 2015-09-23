require "bundler/setup"

require "dotenv"
Dotenv.load

require "pp"

require "eventmachine"
require "tweetstream"
require "em-hiredis"
require "aws-sdk"

require_relative "./sqs_queues"
require_relative "../app/models/user"


def notify_new_tx(tx)
  NotifyAdmin.wallet_notify(tx)
  AdminMailer.wallet_notify(tx).deliver_now
end

def notify_tx(tx)
  NotifyAdmin.wallet_notify(tx)
end


EM.run {
  # Subscribe to new users.
  Rails.logger.info "Subscribing to wallet_notify events"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])

  redis.pubsub.subscribe("wallet_notify") {|msg|
    Rails.logger.info "[REDIS] Wallet notify event from bitcoind: #{msg}"
    json = JSON.parse(msg)

    transaction = B.client.gettransaction(json["txid"])
    Rails.logger.info transaction.to_yaml
    tx = Transaction.create(transaction)
    if tx["confirmations"] == 0
      notify_new_tx(tx)
    else
      notify_tx(tx)
    end
    transaction["details"].each do |detail|
      user = User.update_balance_by_address(detail["address"])
    end
  }
}