#!/bin/bash
## EMAIL FETCHER
## gmail.com - oauth - imap
## called from cron periodically

# SORREND SZÁMÍT!!!!
#rake --trace -f /usr/src/redmine/Rakefile redmine:email:receive_imap RAILS_ENV="production"\
# host=$HOST username=$USER password=$PASS port=993 ssl=SSL \
# unknown_user=accept \
# allow_override=all \
# no_permission_check=1 \
# folder="Redmine" \
# move_on_success="Redmine/read" \
# move_on_failure="Redmine/failed" \
# project=sandbox \
# tracker=Iktatas \
# status=New

# load credentials and config
. .credentials

# create token file dir if not exists
mkdir -p "$(dirname "${token_file}")"

# fetch emails and insert,move,read them
rake --trace -f /usr/src/redmine/Rakefile redmine:email:receive_imap_oauth RAILS_ENV="production"\
 host=$HOST username=$USER port=993 ssl=SSL \
 client_id=$client_id client_secret=$client_secret refresh_token=$refresh_token token_file=$token_file \
 unknown_user=accept \
 allow_override=all \
 no_permission_check=1 \
 folder="Redmine" \
 move_on_success="Redmine/read" \
 move_on_failure="Redmine/failed" \
 project=sandbox \
 tracker=Iktatas \
 status=New

