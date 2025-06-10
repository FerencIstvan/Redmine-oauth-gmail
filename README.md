# Redmine-oauth-gmail

This patch extends Redmine-s email fetcher to be able to read emails via IMAP authenticated by Googles OAUTH.

(I am not a ruby developer, so there could exists better, cleaner solutions, but this worked for me. )

# Usage in short

  0. Create somewhere a simple webpage, where o.html will be reachable. This is will be the reredirect_uri
    it has to be one level before TLD, like: exemple.com/o.html (no subdomains allowed)
  1. allow API, add url to allowed hosts list, etc in google security settings.
    https://developers.google.com/identity/protocols/oauth
  2. Generate PermissionURL by calling the receive_imap_oauth_init task
    INTERACTIVE - call from cli with proper arguments* to follow commands
  4. get permission code
  5. generate first token (it will contain renew_token, which works till revoke)
    - it saves to toke_file 

When you successfully generated the token_file, a valid token with a refresh_token exists. If so, the receive_imap_oauth task 
  - reads it,
  - if the access_token expired renews it with renew_token
  - fetches the mails with access_token and process them in the old way.

Steps 0-2 could be done with python oauth2, i have learned the method from there:
 https://github.com/google/gmail-oauth2-tools/blob/master/python/oauth2.py

# TODO
- find out proper arguments* it was in a docker, and bash history is gone :(
- add notes about generating renew token...
- check credits (i was in hurry)
- add redmine 4.1 version
- add version notes

