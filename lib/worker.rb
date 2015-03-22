def sqs
  @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def queue
  @queue ||= "https://sqs.us-east-1.amazonaws.com/080383581145/TipperNewTip"
end

def find_or_create_account(twitter_id)

end

def receive
  begin
    resp = sqs.receive_message(
      queue_url: queue,
      wait_time_seconds: 20,
    )
    messages = resp.messages.map do |message|
      puts "Found message #{message}"
      [receipt_handle: message.receipt_handle, message: JSON.parse(message.body)]
    end
    messages
  rescue Aws::SQS::Errors::ServiceError
  # rescues all errors returned by Amazon Simple Queue Service
  end
end

def delete(handle)
  resp = sqs.delete_message(
  queue_url: queue,
  receipt_handle: handle,
)
end

EventMachine.run do
  EM.add_periodic_timer(25.0) do
    puts "Ready to process tasks.."
    puts receive
  end
end

