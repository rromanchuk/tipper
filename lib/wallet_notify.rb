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

ARGV[0]

message = { "txid": ARGV[0] }.to_json
Redis.current.publish("wallet_notify", message)