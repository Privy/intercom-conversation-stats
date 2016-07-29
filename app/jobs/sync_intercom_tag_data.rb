class SyncIntercomTagData

  include Sidekiq::Worker

  FIRST_DATA_ROW = 7
  TOTAL_ROW = 6
  MENTIONS_ROW = 5
  WEEK_ROW = 4

  FIRST_DATA_COLUMN = 4
  ALL_TIME_PERCENT_COLUMN = 3
  ALL_TIME_MENTIONS_COLUMN = 2
  TAG_NAME_COLUMN = 1

  def perform most_recent_id
    #access tags from Conversation table filled via webhooks
    tags = IntercomHelper.find_tags(ConversationData.find(most_recent_id).conversation_ids)

    #remove prefixes from tags, remove white space, and capitalize them
    tags.transform_keys! {|tag_name| tag_name.split(" - ").last.strip.titleize}
        
    #access worksheet
    session = GoogleDrive.login_with_oauth(Google::Auth::ServiceAccountCredentials.from_env('https://www.googleapis.com/auth/drive'))
    ws = session.spreadsheet_by_key(ENV['GOOGLE_SPREADSHEET_KEY']).worksheets[0]
        
    #establish column numbers and letters, and row number
    col = ws.num_cols + 1
    col = FIRST_DATA_COLUMN if col < FIRST_DATA_COLUMN
    col2 = col + 1
    col_letters = calculate_column_letters(col)
    col2_letters = calculate_column_letters(col2)
    num_rows = ws.num_rows

    #formatting stuff
    week = ConversationData.find(most_recent_id).created_at
    end_of_week = (week + 6.days).strftime("%m/%d/%Y")
    week = week.strftime("%m/%d/%Y")
    ws[WEEK_ROW, ALL_TIME_MENTIONS_COLUMN] = "6/27/16 - #{end_of_week}"
    ws[WEEK_ROW, col] = "Week of #{week}"
    ws[MENTIONS_ROW, col] = "# of Mentions"
    ws[MENTIONS_ROW, col2] = "% of Mentions"

    #total # mentions and % mentions
    ws[TOTAL_ROW, col] = "=SUM(#{col_letters}#{FIRST_DATA_ROW}:#{col_letters})"
    ws[TOTAL_ROW, col2] = "=SUM(#{col2_letters}#{FIRST_DATA_ROW}:#{col2_letters})"

    #update data
    tags.each do |tag_name, tag_count|
      r = FIRST_DATA_ROW
      until ws[r, TAG_NAME_COLUMN] == tag_name do #find a row whose name matches the tag name
        if r > num_rows #if this tag doesn't match any rows, i.e. it's a new tag
          num_rows = r
          add_new_tag(ws, tag_name, num_rows, col)
        end
        r += 1
      end
      ws[r, col] = tag_count
      ws[r, col2] = "=TO_PERCENT(#{col_letters}#{r}/$#{col_letters}$#{TOTAL_ROW})"
    end 

    #update formulas for "all time mentions" column and check for rows that did not get any new data
    column_letters = []
    c = FIRST_DATA_COLUMN
    until c > col
      column_letters << calculate_column_letters(c)
      c += 2 #we only want "# of mentions" columns
    end
    r = FIRST_DATA_ROW
    until r > num_rows do
      column_string = column_letters.map {|l| "#{l}#{r}"}.join(", ")
      ws[r, ALL_TIME_MENTIONS_COLUMN] = "=SUM(#{column_string})"
      if ws[r, col] == "" #check for rows that did not get any new data, i.e. the tag was deleted
        ws[r, col] = "0"
        ws[r, col2] = "=TO_PERCENT(#{col_letters}#{r}/$#{col_letters}$#{TOTAL_ROW})"
      end
      r += 1
    end

    #THIS IS IMPORTANT - save the worksheet and reload its contents from the server
    ws.synchronize

    #indicate that everything went smoothly
    ConversationData.find(most_recent_id).update(synced: true)
  end

  private

  def calculate_column_letters column
    column -= 1
    s = ""

    loop do
      letter = ((column % 26) + 65).chr
      s << letter
      break if column < 26
      column = (column / 26) - 1
    end

    s.reverse
  end

  def add_new_tag ws, tag_name, row_number, max_columns
    ws[row_number, TAG_NAME_COLUMN] = tag_name
    c = ALL_TIME_PERCENT_COLUMN
    until c >= max_columns do #fill empty columns with values for rows with new tags; also immediately breaks out of the loop if max columns is less than 2
      if c.even?
        ws[row_number,c] = "0"
      else
        letters = calculate_column_letters(c - 1)
        ws[row_number,c] = "=TO_PERCENT(#{letters}#{row_number}/$#{letters}$#{TOTAL_ROW})"
      end
      c += 1
    end
  end

end