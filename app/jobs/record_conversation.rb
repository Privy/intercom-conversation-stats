# Pushes a conversation id into the most recent convo data record
class RecordConversation
  include Sidekiq::Worker

  def perform(conversation_id)
    most_recent = ConversationData.most_recent
    most_recent.conversation_ids << conversation_id
    most_recent.save
  end
end
