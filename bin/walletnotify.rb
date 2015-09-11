#!/usr/bin/env ruby
require "dotenv"
require 'json'
Dotenv.load

require "redis"
Redis.current = Redis.new(url: ENV['REDIS_URL'])

ARGV[0]

message = { "txid": ARGV[0] }.to_json
Redis.current.publish("wallet_notify", message)