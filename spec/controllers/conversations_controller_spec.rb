require 'rails_helper'

describe ConversationsController do

  before(:all) do
    ConversationData.create if ConversationData.count == 0
  end

  EXAMPLE_JSON = {
          "type": "notification_event",
          "topic": "conversation.user.created",
          "id": "notif_ccd8a4d0-f965-11e3-a367-c779cae3e1b3",
          "created_at": 1392731331,
          "delivery_attempts": 1,
          "first_sent_at": 1392731392,
          "data": {
            "item": {
              "type": "conversation",
              "id": "147",
              "created_at": 1400850973,
              "updated_at": 1400857494,
              "conversation_message": {
                "type": "conversation_message",
                "subject": "",
                "body": "<p>Hi Alice,</p>\n\n<p> We noticed you using our Product,  do you have any questions?</p> \n<p>- Jane</p>",
                "author": {
                  "type": "admin",
                  "id": "25"
                },
                "attachments": [
                  {
                    "name": "signature",
                    "url": "http://example.org/signature.jpg"
                  }
                ]
              },
              "user": {
                "type": "user",
                "id": "536e564f316c83104c000020"
              },
              "assignee": {
                "type": "admin",
                "id": "25"
              },
              "open": true,
              "read": true,
              "conversation_parts": {
                "type": "conversation_part.list",
                "conversation_parts": [{
                  "type": "conversation_part",
                  "id": "4412",
                  "part_type": "comment",
                  "body": "<p>Hi Jane, it's all great thanks!</p>",
                  "created_at": 1400857494,
                  "updated_at": 1400857494,
                  "notified_at": 1400857587,
                  "author": {
                    "type": "user",
                    "id": "536e564f316c83104c000020"
                  },
                  "attachments": []
                }]
              },
              "tags": { "type": 'tag.list', "tags": [] }
            }
          }
        }
  
  describe "#create" do
    context "when a new post is received from Intercom" do
      it "should be placed in ConversationData via RecordConversation" do
        post(:create, EXAMPLE_JSON)
        expect('147').to eql(ConversationData.most_recent.conversation_ids.last)
      end
    end
  end

end
