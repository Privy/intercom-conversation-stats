require 'rails_helper'

describe RecordConversation do

  before(:all) do
    ConversationData.create
  end
  
  describe "#perform" do
    context "when a new conversation is created" do
      it "should add the ID to the newest row in ConversationData" do
        RecordConversation.new.perform('123456789')
        expect('123456789').to eql(ConversationData.most_recent.conversation_ids.last)
      end
    end
  end

end
