class ConversationsController < BaseController
before_action :set_request_params, only: [:create]

  def index
    #check google authorization
    begin
      session = GoogleDrive.login_with_oauth(Google::Auth::ServiceAccountCredentials.from_env('https://www.googleapis.com/auth/drive'))
      @google_auth = 1
    rescue
      @google_auth = 0
    end
    if @google_auth == 1
      begin
        session = GoogleDrive.login_with_oauth(Google::Auth::ServiceAccountCredentials.from_env('https://www.googleapis.com/auth/drive'))
        ws = session.spreadsheet_by_key(ENV['GOOGLE_SPREADSHEET_KEY']).worksheets[0]
        @google_auth = 2
      rescue
      end
    end
    #check intercom authorization
    begin
      intercom = Intercom::Client.new(app_id: ENV['INTERCOM_KEY'], api_key: ENV['INTERCOM_SECRET'])
      intercom.admins.all.first
      @intercom_auth = true
    rescue
      @intercom_auth = false
    end
  end

  def create
    Sidekiq::Client.enqueue(RecordConversation, @request_params["data"]["item"]["id"])
    head :ok
  end

end 