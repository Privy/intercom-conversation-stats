# Wrapper around Intercom client
module IntercomHelper
  APP_ID = ENV['INTERCOM_KEY']
  API_KEY = ENV['INTERCOM_SECRET']

  # Creates a hash of tag names and the number of times they were mentioned from
  # the data in ConversationData
  #
  # @param [Array<String>] conversation_ids - the intercom conversation ids
  # @return [Hash<String, Integer>]
  def self.find_tags(conversation_ids)
    {}.tap do |tags|
      conversations(conversation_ids).each do |conversation|
        conversation.tags.each do |tag|
          tags[tag.name] ||= 0
          tags[tag.name] += 1
        end
      end
    end
  end

  # @return [Inctercom::Client]
  def self.client
    # @todo use access tokens
    @client ||= Intercom::Client.new(app_id: APP_ID, api_key: API_KEY)
  end

  def self.conversations(ids)
    ids.map do |id|
      # Protect from API rate limiting
      sleep 0.2

      begin
        client.conversations.find(id: id)
      rescue Intercom::ResourceNotFound
        # Ignore 404 errors (conversation not found)
        nil
      end
    end.compact
  end
  private_class_method :conversations
end
