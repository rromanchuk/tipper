#!/usr/bin/env ruby


ARGV[0]

message = { "txid": ARGV[0] }.to_json
Redis.current.publish("wallet_notify", message)