#!/usr/bin/env ruby
require 'aws-sdk'

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sqs
  sqs = Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end


ARGV[0]

sqs.send_message(queue_url: "https://sqs.us-east-1.amazonaws.com/080383581145/WalletNotify", message_body: { "txid": ARGV[0] }.to_json )