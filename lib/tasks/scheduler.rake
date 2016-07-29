# Scheduled Tasks
#=========================

namespace :scheduler do
  
  # NOT idempotent, so only run once per WEEK max
  desc "Gather weekly tag info from our intercom conversations"
  task :sync_intercom_tag_data => :environment do
    if Date.today.wday == 1
      most_recent_id = ConversationData.most_recent.id
      Sidekiq::Client.enqueue(SyncIntercomTagData, most_recent_id)
      new_most_recent = ConversationData.create
    end
  end
  
end
