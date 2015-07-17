class NotifyAdmin
  TOPIC = "arn:aws:sns:us-east-1:080383581145:AdminNotification"


  def self.new_user(username)
    send "New user: #{username}"
  end

  def self.external_deposit
    send "External deposit"
  end

  def self.withdrawl
    send "Withdrawl out"
  end

  def self.reserves_depleted
    send "Reserves are depleted"
  end

  def self.fund_event
    send  "New funding event"
  end

  def self.send(message)
    apns_payload = { "aps" => { "alert" => message, "badge" => 1 } }.to_json
    resp = sns.publish(
      topic_arn: TOPIC,
      message_structure: "json",
      message: {"default" => message, "APNS_SANDBOX": apns_payload, "APNS": apns_payload, "sms": message }.to_json
    )
  end

  private

  def self.sns
     @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

end