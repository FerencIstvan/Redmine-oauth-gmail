# Redmine-oauth-gmail

This patch extends Redmine-s email fetcher to be able to read emails via IMAP authenticated by Googles OAUTH.

(I am not a ruby developer, so there could exists better, cleaner solutions, but this worked for me. )

# Usage in short

0. Create somewhere a simple webpage, where o.html will be reachable.
  *  This is the reredirect_uri.
  *  It has to be one level before TLD, like: exemple.com/o.html (no subdomains where allowed when I tried)
1. Allow API, add url to allowed hosts list, etc in google security settings.
  * https://developers.google.com/identity/protocols/oauth
2. Generate PermissionURL by calling the receive_imap_oauth_init task
  * INTERACTIVE - call from cli with proper arguments like initgmail.sh and follow commands
3. Get permission code
4. Generate first token (it will contain renew_token, which works till revoke)
  * it saves to token_file 
5. Call receive_imap_oauth to fetch mails like fetchmail.sh or as you want. 



When you successfully generated the token_file, a valid access_token with a refresh_token exists. If so, the receive_imap_oauth task 
  - reads it,
  - if the access_token expired renews it with renew_token
  - fetches the mails with access_token and process them in the old way.


Access tokens usually valid one hour only. 


Steps 0-2 could be done with python oauth2, i have learned the method from there:

 https://github.com/google/gmail-oauth2-tools/blob/master/python/oauth2.py

# TODO
- check credits (i was in hurry)
- add modified patch for easy-redmine4.1
