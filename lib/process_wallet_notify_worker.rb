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


def notify_admins(tx)
  begin
    message = "#{tx["category"]}: #{tx["amount"]}"
    resp = sns.publish(
      topic_arn: "arn:aws:sns:us-east-1:080383581145:WalletTransaction",
      message_structure: "json",
      message: {"default" => message, "sms": message }.to_json
    )
  rescue Aws::SNS::Errors::EndpointDisabled
    Rails.logger.error "Aws::SNS::Errors::EndpointDisabled"
  end

  AdminMailer.wallet_notify(tx).deliver_now
end

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end


EM.run {
  # Subscribe to new users.
  Rails.logger.info "Subscribing to wallet_notify events"
  redis = EM::Hiredis.connect(ENV["REDIS_URL"])

  redis.pubsub.subscribe("wallet_notify") {|msg|
    Rails.logger.info "[REDIS] Wallet notify event from bitcoind: #{msg}"
    json = JSON.parse(msg)
    
    transaction = B.client.gettransaction(json["txid"])
    tx = Transaction.create(transaction)
    if tx["confirmations"] == 0
      notify_admins(tx)
    end
    transaction["details"].each do |detail|
      user = User.update_balance_by_address(detail["address"])
    end
  }
}