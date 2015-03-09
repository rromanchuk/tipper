require 'bitcon_client'
class B
  def client
    @client ||= BitcoinClient::Client.new(ENV["RPC_USERNAME"], ENV["RPC_PASSWORD"])
  end

  def balance
    client.balance
  end
end