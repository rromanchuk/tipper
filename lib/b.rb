require 'bitcon_client'
class B
  def client
    @client ||= Bitcoin::Client.new(ENV["RPC_USER"], ENV["RPC_PASSWORD"])
  end

  def balance
    client.balance
  end
end