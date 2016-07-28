class ConversationData < ActiveRecord::Base

  def self.most_recent
    self.order(created_at: :desc).first
  end

end 