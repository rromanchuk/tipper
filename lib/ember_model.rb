require 'active_model'

module EmberModel
  def included(base) #its a callback called after models are included
    base.class_eval do
      include ActiveModel::Serializers
      include ActiveModel::Model
    end
  end #end def included

  def as_json(options={})
    camelize_keys(super(options))
  end

  def camelize_keys(hash)
    values = hash.map do |key, value|
      [key.camelize(:lower), value]
    end
    Hash[values]
  end

  def self.db
    @dynamodb ||= Aws::DynamoDB::Client.new(region: 'us-east-1', credentials: Aws::SharedCredentials.new)
  end

  def db
    EmberModel.db
  end

end