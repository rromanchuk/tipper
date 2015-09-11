#!/usr/bin/env ruby
require "dotenv"
require 'json'
Dotenv.load

require "redis"

ARGV[0]

message = { "txid": ARGV[0] }.to_json
Redis.current.publish("wallet_notify", message)