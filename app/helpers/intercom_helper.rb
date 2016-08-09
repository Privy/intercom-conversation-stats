module IntercomHelper

  # Create a hash of tag names and the number of times they were mentioned from the data in ConversationData
  #
  # @param [Array<String>] conversation_ids - the intercom conversation ids
  # @return [Hash<String, Integer>]
  def self.find_tags conversation_ids
    intercom = Intercom::Client.new(app_id: ENV['INTERCOM_KEY'], api_key: ENV['INTERCOM_SECRET'])

    tags = {}

    conversations = conversation_ids.map do |id|
      # Protect from API rate limiting
      sleep 0.2

      begin
        intercom.conversations.find(id: id)
      rescue Intercom::ResourceNotFound
        # Ignore 404 errors (conversation not found)
        nil
      end
    end.compact

    conversations.each do |conversation|
      conversation.tags.each do |tag|
        tags[tag.name] ||= 0
        tags[tag.name] += 1
      end
    end

    tags
  end
end
