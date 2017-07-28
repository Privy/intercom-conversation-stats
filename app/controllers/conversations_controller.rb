class ConversationsController < BaseController
before_action :set_request_params, only: [:create]

  def index
    #check google authorization
    begin
      session = GoogleDrive.login_with_oauth(Google::Auth::ServiceAccountCredentials.from_env('https://www.googleapis.com/auth/drive'))
      @google_auth = 1
      begin
        ws = session.spreadsheet_by_key(ENV['GOOGLE_SPREADSHEET_KEY']).worksheets[0]
        @google_auth = 2
      rescue Google::Apis::ClientError
      end
    rescue RuntimeError
      @google_auth = 0
    end
    #check intercom authorization
    begin
      intercom = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN']);
      intercom.admins.all.first
      @intercom_auth = true
    rescue
      @intercom_auth = false
    end
  end

  def create
    # To record this asynchronously:
    # Sidekiq::Client.enqueue(RecordConversation, @request_params["data"]["item"]["id"])
    RecordConversation.new.perform(@request_params["data"]["item"]["id"])
    head :ok
  end

end 