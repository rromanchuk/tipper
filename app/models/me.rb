require 'active_model'

class Me
  include ActiveModel::Serialization
  include ActiveModel::Model
  
  def initialize(user_from_dynamo={})
    @user_id = user_from_dynamo["UserID"]
    @bitcoin_address = user_from_dynamo["BitcoinAddress"]
    @twitter_user_id = user_from_dynamo["TwitterUserID"]
    @twitter_username = user_from_dynamo["TwitterUsername"]
    @profile_image = user_from_dynamo["ProfileImage"]
  end

  def attributes
    {'userId': user_id, 'twitterUserId': twitter_user_id, 'twitterUsername': twitter_username, 'bitcoinAddress': bitcoin_address, 'profileImage': profile_image}
  end

end