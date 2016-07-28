class SyncIntercomTagData

  include Sidekiq::Worker

  FIRST_DATA_ROW = 7
  TOTAL_ROW = 6
  MENTIONS_ROW = 5
  WEEK_ROW = 4

  FIRST_DATA_COLUMN = 4
  ALL_TIME_COLUMN = 2
  TAG_NAME_COLUMN = 1

  def perform most_recent_id
    #access tags from Conversation table filled via webhooks
    tags = IntercomHelper.find_tags(ConversationData.find(most_recent_id).conversation_ids)

    #remove prefixes from tags, remove white space, and capitalize them
    tags.each do |tag_name, tag_count|
      tags[tag_name.split(" - ").last.strip.titleize] = tag_count
      tags.delete(tag_name)
    end
        
    #access worksheet
    session = GoogleDrive.login_with_oauth(Google::Auth::ServiceAccountCredentials.from_env('https://www.googleapis.com/auth/drive'))
    ws = session.spreadsheet_by_key(ENV['GOOGLE_SPREADSHEET_KEY']).worksheets[0]
        
    #establish column numbers and letters, and row number
    col = ws.num_cols + 1
    col2 = col + 1
    col_letters = calculate_column_letters(col)
    col2_letters = calculate_column_letters(col2)
    num_rows = ws.num_rows

    #formatting stuff
    week = ConversationData.find(most_recent_id).created_at.strftime("%m/%d/%Y")
    ws[WEEK_ROW, ALL_TIME_COLUMN] = "6/27/16 - #{week + 6.days}"
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
        r += 1
        if r > num_rows #if this tag doesn't match any rows, i.e. it's a new tag
          num_rows = r
          add_new_tag(ws, tag_name, num_rows, col)
        end
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
      edit_all_time_mentions(column_letters, r)
      if ws[r, col] == "" #check for rows that did not get any new data, i.e. the tag was deleted
        ws[r, col] = "0"
        ws[r, col2] = "=TO_PERCENT(#{col_letters}#{r}/$#{col_letters}$#{TOTAL_ROW})"
      end
      r +=1
    end

    #THIS IS IMPORTANT - save the worksheet and reload its contents from the server
    ws.synchronize

    #indicate that everything went smoothly
    ConversationData.find(most_recent_id).update(synced: true)
  end

  private

  def calculate_column_letters column, s = ""
    column -= 1
    right_most = column % 26
    letter = (right_most + 65).chr
    s = letter + s
    return s if column < 26

    now = column / 26 - 1
    return (calculate_column_letters(now, s))
  end

  def add_new_tag ws, tag_name, row_number, max_columns
    ws[row_number, TAG_NAME_COLUMN] = tag_name
    c = FIRST_DATA_COLUMN
    until c >= max_columns do #fill empty columns with values for rows with new tags; also immediately breaks out of the loop if max columns is less than 2
      if c.even?
        ws[row_number,c] = "0"
      else
        letters = calculate_column_letters(c)
        ws[row_number,c] = "=TO_PERCENT(#{letters}#{row_number}/$#{letters}$6)"
      end
      c += 1
    end
  end

  def edit_all_time_mentions column_letters, row_number
    column_ids = column_letters.map {|l| l + "#{row_number}"}
    column_string = ""
    column_ids.each do |id| 
      column_string += id 
      column_string += ", " unless column_ids.last == id
    end
    ws[r, ALL_TIME_COLUMN] = "=SUM(#{column_string})"
  end

end