# Intercom Conversation Stats

Aggregates intercom conversation tags on a weekly basis, and presents the data in a Google Sheets document.

## Documentation for Gems Used
* [intercom-ruby](https://github.com/intercom/intercom-ruby)
* [google-drive-ruby](https://github.com/gimite/google-drive-ruby)
* [Specific documentation for working with sheets](http://www.rubydoc.info/gems/google_drive/GoogleDrive/Worksheet)

## Setup

### Heroku
* Create a new spreadsheet in Google Drive.
* Create an OAuth 2.0 service account in the [Google APIs Credentials Manager](https://console.developers.google.com/apis/credentials)
* Clone the repository.
* Follow the Heroku docs [to deploy the application to Heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4#deploy-your-application-to-heroku).
* Add the following services:

  ```shell
  heroku addons:create rediscloud:30
  heroku addons:create heroku-postgresql:hobby-dev
  heroku addons:create scheduler:standard
  ```
* Migrate the database.
* In the heroku scheduler, add a daily task to run `bundle exec rake scheduler:sync_intercom_tag_data`
* Configure the following required environment variables:

  ```shell
  GOOGLE_CLIENT_EMAIL
  GOOGLE_PRIVATE_KEY
  GOOGLE_SPREADSHEET_KEY
  INTERCOM_KEY
  INTERCOM_SECRET
  ```

* Add a [webhook](https://docs.intercom.io/integrations/webhooks) via your Intercom settings with the topic "New Message from a User" and the webhook URL `<yourheroku app>.herokuapp.com/conversations`
* Visit your new app at `<your heroku app>.herokuapp.com` - if it all went well, you should see no error messages.

## Customization
This app is written in Ruby on Rails.
### Data Gathered
To aggregate data other than tags, add a new method to `app/helpers/intercom_helper.rb`. Make sure it is a class method by naming it `self.method_name` and make sure you replace the call to `find_tags` in `app/jobs/sync_intercom_tag_data.rb`.
### Sheet Update Frequency
By default, your Google Sheets document will be updated every week on Monday. To change how often or which day your Sheet is updated, edit `lib/tasks/scheduler.rake`. Note that you may also have to edit `app/jobs/sync_intercom_tag_data.rb` if you make your Sheet update more often than weekly, because the columns display "Week of <week>" for each update by default.
### Sheet Layout
The layout of the Google Sheets document can be customized by editing `app/jobs/sync_intercom_tag_data.rb`. This Sidekiq job uses the [google-drive-ruby gem](https://github.com/gimite/google-drive-ruby) to edit the Sheets document. Read [here](http://www.rubydoc.info/gems/google_drive/GoogleDrive/Worksheet) for the full documentation for the relevant part of that gem. **NOTE: If you have formulas or color-coding in ANY of your cells, DO NOT use the `delete_rows` or `insert_rows` methods. These will delete any formulas and mess up cell colors for your entire Sheet!** Color-coding of cells is not supported by this gem, so an alternate way to automatically color code your data in Sheets is via [conditional formatting](https://support.google.com/docs/answer/78413?co=GENIE.Platform%3DDesktop&hl=en).
