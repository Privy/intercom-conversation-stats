module IntercomHelper

  #create a hash of tag names and the number of times they were mentioned from the data in ConversationData
  def self.find_tags conversation_ids
    intercom = Intercom::Client.new(app_id: ENV['INTERCOM_KEY'], api_key: ENV['INTERCOM_SECRET'])

    tags = {}

    conversations = conversation_ids.map do |id|
      sleep 0.2
      intercom.conversations.find(id: id)
    end

    conversations.each do |conversation|
      conversation.tags.each do |tag|
        tags[tag.name] ||= 0
        tags[tag.name] += 1
      end
    end

    tags
  end

end
