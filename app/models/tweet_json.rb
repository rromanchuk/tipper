class TweetJson
	include EmberModel

  TABLE_NAME = "TweetJSON"
  UPDATE_EXPRESSION = "SET " +
                              "TweetJSON = :tweet_json "
  
  def initialize(tip_from_dynamo)
    @id                         = tip_from_dynamo["ObjectID"]
    @tweet_json                 = tip_from_dynamo["TweetJSON"] 
  end

  def self.create(tweet)
    resp = db.update_item(
      # required
      table_name: Tip::TABLE_NAME,
      return_values: "ALL_NEW",
      # required
      key: {
        "ObjectID" =>  tweet.id.to_s,
      },
      update_expression: UPDATE_EXPRESSION,
      expression_attribute_values: {
                                    ":tweet_json": tweet.to_json
                                   })

    resp.attributes
  end
                             
end