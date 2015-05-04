#!/usr/bin/env ruby
require 'aws-sdk'

def sns
  @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sqs
  sqs = Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end


ARGV[0]

sqs.send_message(queue_url: "***REMOVED***", message_body: { "txid": ARGV[0] }.to_json )