class Me
  include EmberModel

  def initialize(user_from_dynamo={})
    @id = user_from_dynamo["UserID"]
    @bitcoin_address = user_from_dynamo["BitcoinAddress"]
    @twitter_user_id = user_from_dynamo["TwitterUserID"]
    @twitter_username = user_from_dynamo["TwitterUsername"]
    @profile_image = user_from_dynamo["ProfileImage"]
    @user_id = user_from_dynamo["UserID"]
    @bitcoin_balance_btc = user_from_dynamo["BitcoinBalanceBTC"]
  end

end