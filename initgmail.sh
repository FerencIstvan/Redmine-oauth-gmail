#!/bin/bash
## google oauth2 init script

# storing credentials in script files is not a secure way, but keeps git repo small. Please refactor it for production!
PASS="not used in OAUTH method anymore"
HOST="imap.gmail.com"
USER="<user email address>"
token_file="/usr/src/redmine/scripts/tokens/token.yml"
client_id="<client id from google api console>"
client_secret="<client secret from google api console>"
refresh_token=""
#alternatively refresh token can be created by python3 oauth2.py --generate_oauth2_token --client_id=$client_id --client_secret=$client_secret
redirect_uri="<example.com/o.html>"

# create token file dir if not exists
mkdir -p "$(dirname "${token_file}")"

# fetch emails and insert,move,read them
rake --trace -f /usr/src/redmine/Rakefile redmine:email:receive_imap_oauth_init RAILS_ENV="production"\
 host=$HOST username=$USER port=993 ssl=SSL \
 client_id=$client_id client_secret=$client_secret refresh_token=$refresh_token token_file=$token_file \
 redirect_uri=$redirect_uri
