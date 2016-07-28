class SyncIntercomTagData

  include Sidekiq::Worker

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
    ws[4, 2] = "6/27/16 - #{week + 6.days}"
    ws[4, col] = "Week of #{week}"
    ws[5, col] = "# of Mentions"
    ws[5, col2] = "% of Mentions"

    #total # mentions and % mentions
    ws[6, col] = "=SUM(#{col_letters}7:#{col_letters})"
    ws[6, col2] = "=SUM(#{col2_letters}7:#{col2_letters})"

    #update data
    tags.each do |tag_name, tag_count|
      r = 7
      until ws[r, 1] == tag_name do #find a row whose name matches the tag name
        r += 1
        if r > num_rows #if this tag doesn't match any rows, i.e. it's a new tag
          num_rows += 1
          add_new_tag(ws, tag_name, num_rows, col)
        end
      end
      ws[r, col] = tag_count
      ws[r, col2] = "=TO_PERCENT(#{col_letters}#{r}/$#{col_letters}$6)"
    end 

    #check for rows that did not get any new data, i.e. the tag was deleted
    r = 7
    until r > num_rows do
      if ws[r, col] == ""
        ws[r, col] = "0"
        ws[r, col2] = "=TO_PERCENT(#{col_letters}#{r}/$#{col_letters}$6)"
      end
      r +=1
    end

    #THIS IS IMPORTANT - save the worksheet and reload its contents from the server
    ws.synchronize

    #indicate that everything went smoothly
    ConversationData.find(most_recent_id).update(synced: true)
  end

  private

  def calculate_column_letters column
    column -= 1
    i = column%26
    n = (column-i)/26
    s = (i+65).chr
    s = (n+65).chr.concat(s) if n > 0
    return s
  end

  def add_new_tag(ws, tag_name, row_number, max_columns)
    raise ArgumentError, "max columns must be > 1" if max_columns < 1
    ws[row_number, 1] = tag_name
    c = 2
    until c >= max_columns do #fill empty columns with values for rows with new tags; also immediately breaks out of the loop if max columns is less than 2
      if c.even?
        ws[row_number,c] = "0"
      else
        letters = calculate_column_letters(c - 1)
        ws[row_number,c] = "=TO_PERCENT(#{letters}#{row_number}/$#{letters}$6)"
      end
      c += 1
    end
  end

end