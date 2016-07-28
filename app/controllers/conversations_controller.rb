class ConversationsController < BaseController
before_action :set_request_params, only: [:create]

	def create
		Sidekiq::Client.enqueue(RecordConversation, @request_params["data"]["item"]["id"])
		head :ok
	end

end 