def sqs
  @sqs ||= Aws::SQS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def queue
  @queue ||= "***REMOVED***"
end

def cognito
  @cognito ||= Aws::CognitoIdentity::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def sync
  @sync ||= Aws::CognitoSync::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
end

def identityPool
  @identityPool ||= "us-east-1:71450ec4-894b-4e51-bfbb-35a012b5b514"
end


def process
  identity = cognito.lookup_developer_identity(
  identity_pool_id: identityPool,
  developer_user_identifier: "msiegs",
  max_results: 1,
  )
  puts identity

  
  resp = sync.list_records(
    identity_pool_id: identityPool,
    identity_id: identity.identity_id,
    max_results: 1,
    dataset_name: "Profile",
  )
  
  hash = {}
  resp.records.each do |record|
    hash[record.key] = record.value
  end

  puts hash.inspect
  resp
end

process

# def receive
#   begin
#     resp = sqs.receive_message(
#       queue_url: queue,
#       wait_time_seconds: 20,
#     )
#     messages = resp.messages.map do |message|
#       puts "Found message #{message}"
#       [receipt_handle: message.receipt_handle, message: JSON.parse(message.body)]
#     end
#     messages
#   rescue Aws::SQS::Errors::ServiceError
#   # rescues all errors returned by Amazon Simple Queue Service
#   end
# end




# def delete(handle)
#   resp = sqs.delete_message(
#   queue_url: queue,
#   receipt_handle: handle,
# )
# end

# EventMachine.run do
#   EM.add_periodic_timer(25.0) do
#     puts "Ready to process tasks.."
#     puts receive
#   end
# end

