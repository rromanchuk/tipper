class TestNotifications
  def sns
    @sns ||= Aws::SNS::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def test_error
    begin

    apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 1 }, "user" => "test", "message" => { "type" => "error", "title" => "Testing notifications", "subtitle" => "This is the sbutitle for the test message"} }.to_json
      resp = sns.publish(
        topic_arn: "arn:aws:sns:us-east-1:080383581145:GeneralNotification",
        message_structure: "json",
        message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    end
  end

  def test_success
    begin

    apns_payload = { "aps" => { "alert" => "Received a favorite from tweet stream", "badge" => 1 }, "user" => "test", "message" => { "type" => "success", "title" => "Testing notifications", "subtitle" => "This is the sbutitle for the test message"} }.to_json
      resp = sns.publish(
        topic_arn: "arn:aws:sns:us-east-1:080383581145:GeneralNotification",
        message_structure: "json",
        message: {"default" => "Received a favorite from tweet stream", "APNS_SANDBOX": apns_payload, "APNS": apns_payload }.to_json
      )
    rescue Aws::SNS::Errors::EndpointDisabled
      logger.error "Aws::SNS::Errors::EndpointDisabled"
    end
  end
end