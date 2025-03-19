# Redmine - project management software
# Copyright (C) 2006-  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'oauth2'
#require "faraday"

namespace :redmine do
  namespace :email do

    desc <<-END_DESC
Read an email from standard input.

See redmine:email:receive_imap for more options and examples.
END_DESC

    task :read => :environment do
      Mailer.with_synched_deliveries do
        MailHandler.safe_receive(STDIN.read, MailHandler.extract_options_from_env(ENV))
      end
    end

    desc <<-END_DESC
Read emails from an IMAP server.

Available IMAP options:
  host=HOST                IMAP server host (default: 127.0.0.1)
  port=PORT                IMAP server port (default: 143)
  ssl=SSL                  Use SSL/TLS? (default: false)
  starttls=STARTTLS        Use STARTTLS? (default: false)
  username=USERNAME        IMAP account
  password=PASSWORD        IMAP password
  folder=FOLDER            IMAP folder to read (default: INBOX)

Processed emails control options:
  move_on_success=MAILBOX  move emails that were successfully received
                           to MAILBOX instead of deleting them
  move_on_failure=MAILBOX  move emails that were ignored to MAILBOX

User and permissions options:
  unknown_user=ACTION      how to handle emails from an unknown user
                           ACTION can be one of the following values:
                           ignore: email is ignored (default)
                           accept: accept as anonymous user
                           create: create a user account
  no_permission_check=1    disable permission checking when receiving
                           the email
  no_account_notice=1      disable new user account notification
  no_notification=1        disable email notification to new user
  default_group=foo,bar    adds created user to foo and bar groups

Issue attributes control options:
  project=PROJECT          identifier of the target project
  project_from_subaddress=ADDR
                           select project from subaddress of ADDR found
                           in To, Cc, Bcc headers
  status=STATUS            name of the target status
  tracker=TRACKER          name of the target tracker
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority
  assigned_to=ASSIGNEE     assignee (username or group name)
  fixed_version=VERSION    name of the target version
  private                  create new issues as private
  allow_override=ATTRS     allow email content to set attributes values
                           ATTRS is a comma separated list of attributes
                           or 'all' to allow all attributes to be overridable
                           (see below for details)

Overrides:
  ATTRS is a comma separated list of attributes among:
  * project, tracker, status, priority, category, assigned_to, fixed_version,
    start_date, due_date, estimated_hours, done_ratio
  * custom fields names with underscores instead of spaces (case insensitive)

  Example: allow_override=project,priority,my_custom_field

  If the project option is not set, project is overridable by default for
  emails that create new issues.

  You can use allow_override=all to allow all attributes to be overridable.

Examples:
  # No project specified. Emails MUST contain the 'Project' keyword:

  rake redmine:email:receive_imap RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@example.net password=xxx


  # Fixed project and default tracker specified, but emails can override
  # both tracker and priority attributes:

  rake redmine:email:receive_imap RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@example.net password=xxx ssl=1 \\
    project=foo \\
    tracker=bug \\
    allow_override=tracker,priority
END_DESC

# plain old password authentication
# will be disabled by gmail on 2025-03-14
    task :receive_imap => :environment do
      imap_options = {:host => ENV['host'],
                      :port => ENV['port'],
                      :ssl => ENV['ssl'],
                      :starttls => ENV['starttls'],
                      :username => ENV['username'],
                      :password => ENV['password'],
                      :folder => ENV['folder'],
                      :move_on_success => ENV['move_on_success'],
                      :move_on_failure => ENV['move_on_failure']}

      Mailer.with_synched_deliveries do
        Redmine::IMAP.check(imap_options, MailHandler.extract_options_from_env(ENV))
      end
    end


# new oauth2 access_token generating - INTERACTIVE - call from cli to follow commands
    task :receive_imap_oauth_init => :environment do

      client_id	    = ENV['client_id'];
      client_secret = ENV['client_secret'];
      refresh_token = ENV['refresh_token'];
      token_file    = ENV['token_file'];

      #0. allow API, add url to allowed hosts list, etc in google security settings.

      #1. Generate PermissionURL
      params = {
        client_id: client_id,
        redirect_uri: ENV['redirect_uri'],
        scope: 'https://mail.google.com',
        response_type: "code",
        access_type: "offline",
        prompt: "consent",
      };
      par_str = URI.encode_www_form(params);
      url = "https://accounts.google.com/o/oauth2/auth?#{par_str}";
      print(" - open this URL in a browser,\n");
      print(" - sign in as #{ENV['username']}\n");
      print(" - grant access, and copy the printed code,\n\n");
      print(url);

      #2. get permission code
      print("\n\nEnter access code from redirect_uri:\n");
      acode = STDIN.gets.chomp;
      #print("ACODE: #{acode}");


      #3. generate first token (it will contain renew_token, which works till revoke)
      client = OAuth2::Client.new(
	client_id,
	client_secret,
	site: 'https://accounts.google.com',
	authorize_url: '/o/oauth2/auth',
	token_url: '/o/oauth2/token',
      )
      params={ 
	grant_type:"authorization_code",
        redirect_uri: ENV['redirect_uri'],
	code: acode
      };
      access_token = client.get_token(params);

      if (access_token.response.response.env.status == 200)
        #print("\n Token type: #{access_token.token_type}");
        print("\n Token valid: #{access_token.expires_in} s");
        #print("\n Access token: #{access_token.token}");
        print("\n Refresh token: #{access_token.refresh_token}");

        File.write(token_file, access_token.to_hash.to_yaml)

        print("\nFirst token saved, can be used and renewed");
      else
          print("\n Error: Response: #{access_token.response.response.env.status}");
          print(access_token.inspect);
      end

    end

#new oauth2 bases authentication for gmail!
    task :receive_imap_oauth => :environment do

      client_id	    = ENV['client_id'];
      client_secret = ENV['client_secret'];
      refresh_token = ENV['refresh_token'];
      token_file    = ENV['token_file'];

      ### simple http post to test renewing token
      #ppp = {
      #	client_id:client_id,
      #	client_secret:client_secret,
      #	refresh_token:refresh_token,
      #	grant_type:"refresh_token"
      #}
      #response = Faraday.post "https://accounts.google.com/o/oauth2/token" do |request|
      #  request.body = URI.encode_www_form(ppp)
      #end
      #print(response.status);
      #print(response.body);
      #abort("\nEND\n");

      ### oauth solution
      client = OAuth2::Client.new(
	client_id,
	client_secret,
	scope: 'https://mail.google.com',
	site: 'https://accounts.google.com',
	authorize_url: '/o/oauth2/auth',
	token_url: '/o/oauth2/token',
      )
      #access_token = client.get_token(params);

      # create tokenfile if not exists
      if (!File.exist?(token_file))
	# https://www.rubydoc.info/gems/oauth2/2.0.9/OAuth2/AccessToken#initialize-instance_method
	print("*** creating empty token \n");
	access_token = OAuth2::AccessToken.new(
	  client,
	  "",
	  refresh_token:refresh_token,
	  expires_at:Time.now.to_i
	)
	File.write(token_file, access_token.to_hash.to_yaml)
      end

      # load access_token from file
      tf = YAML.load_file(token_file,permitted_classes: [SnakyHash::StringKeyed,Symbol]);
      access_token = OAuth2::AccessToken.from_hash(client, tf)

      # renew if needed
      if access_token.expired?
        print("*** token expired, recreating");
        access_token = access_token.refresh!
        File.write(token_file, access_token.to_hash.to_yaml)
        print(" - ok\n");
      #else
      #  print("*** token valid\n");
      end

      print("*** fetching mails...\n");
      imap_options = {:host => ENV['host'],
                      :port => ENV['port'],
                      :ssl => ENV['ssl'],
                      :starttls => ENV['starttls'],
                      :username => ENV['username'],
                      :password => access_token.token,
                      :auth_type => 'XOAUTH2',
                      :folder => ENV['folder'],
                      :move_on_success => ENV['move_on_success'],
                      :move_on_failure => ENV['move_on_failure']}

      Mailer.with_synched_deliveries do
        Redmine::IMAP.check(imap_options, MailHandler.extract_options_from_env(ENV))
      end
    end

    desc <<-END_DESC
Read emails from an POP3 server.

Available POP3 options:
  host=HOST                POP3 server host (default: 127.0.0.1)
  port=PORT                POP3 server port (default: 110)
  username=USERNAME        POP3 account
  password=PASSWORD        POP3 password
  apop=1                   use APOP authentication (default: false)
  ssl=SSL                  Use SSL? (default: false)
  delete_unprocessed=1     delete messages that could not be processed
                           successfully from the server (default
                           behaviour is to leave them on the server)

See redmine:email:receive_imap for more options and examples.
END_DESC

    task :receive_pop3 => :environment do
      pop_options  = {:host => ENV['host'],
                      :port => ENV['port'],
                      :apop => ENV['apop'],
                      :ssl => ENV['ssl'],
                      :username => ENV['username'],
                      :password => ENV['password'],
                      :delete_unprocessed => ENV['delete_unprocessed']}

      Mailer.with_synched_deliveries do
        Redmine::POP3.check(pop_options, MailHandler.extract_options_from_env(ENV))
      end
    end

    desc "Send a test email to the user with the provided login name"
    task :test, [:login] => :environment do |task, args|
      include Redmine::I18n
      abort l(:notice_email_error, "Please include the user login to test with. Example: rake redmine:email:test[login]") if args[:login].blank?

      user = User.find_by_login(args[:login])
      abort l(:notice_email_error, "User #{args[:login]} not found") unless user && user.logged?

      begin
        Mailer.deliver_test_email(user)
        puts l(:notice_email_sent, user.mail)
      rescue => e
        abort l(:notice_email_error, e.message)
      end
    end
  end
end
