class NotifyAdmin
  TOPIC = "arn:aws:sns:us-east-1:080383581145:AdminNotification"
  
  def self.new_user(username)
    message =  "New user: #{username}"
    apns_payload = { "aps" => { "alert" => message, "badge" => 1 } }.to_json
    resp = sns.publish(
      topic_arn: TOPIC,
      message_structure: "json",
      message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload, "sms": message }.to_json
    )
  end

  def self.external_deposit

  end

  def self.withdrawl

  end

  def self.reserves_depleted

  end

  def self.fund_event

  end

  private

  def self.sns
     @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end