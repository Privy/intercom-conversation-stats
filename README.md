# Intercom Conversation Stats

Aggregates intercom conversation tags on a weekly basis, and presents the data in a Google Sheets document.

# Setting up on Heroku
* Create a new spreadsheet in Google Drive.
* Create an OAuth 2.0 service account in the [Google APIs Credentials Manager](https://console.developers.google.com/apis/credentials)
* Clone the repository.
* Follow the Heroku docs [to deploy the application to Heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4#deploy-your-application-to-heroku).
* Add the following services: [commandline todo]
* Migrate the database.
* In the heroku scheduler, add a daily task to run `bundle exec rake scheduler:sync_intercom_tag_data`
* Configure the following required environment variables:
```
GOOGLE_CLIENT_EMAIL
GOOGLE_PRIVATE_KEY
GOOGLE_SPREADSHEET_KEY
INTERCOM_KEY
INTERCOM_SECRET
```
* Add a [webhook](https://docs.intercom.io/integrations/webhooks) from your intercom app to `<yourheroku app>.herokupp.com/conversations`
* Visit your new app at `<your heroku app>.herokuapp.com` - if it all went well, you should see no error messages.
