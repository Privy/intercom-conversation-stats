# Models intercom conversations
class ConversationData < ActiveRecord::Base
  def self.most_recent
    order(created_at: :desc).first
  end
end
