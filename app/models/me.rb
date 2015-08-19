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

  def as_json(options={})
    camelize_keys(super(options))
  end

  private
  def camelize_keys(hash)
    values = hash.map do |key, value|
      [key.camelize(:lower), value]
    end
    Hash[values]
  end

end