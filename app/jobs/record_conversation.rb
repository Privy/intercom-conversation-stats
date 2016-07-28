class RecordConversation
  include Sidekiq::Worker
  sidekiq_options :queue => :maintenance

  def perform conversation_id
    most_recent = ConversationData.most_recent
    most_recent.conversation_ids << conversation_id
    most_recent.save
  end

end