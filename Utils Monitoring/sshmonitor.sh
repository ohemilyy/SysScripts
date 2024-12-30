#!/bin/bash
WEBHOOK_URL="YOUR_DISCORD_WEBHOOK_URL"
case "$PAM_TYPE" in
    open_session)
        PAYLOAD="{
            \"content\": \"\",
            \"embeds\": [{
                \"title\": \"$PAM_USER logged in\",
                \"description\": \"Remote host: $PAM_RHOST\",
                \"color\": 65280
            }]
        }"
        ;;
    close_session)
        PAYLOAD="{
            \"content\": \"\",
            \"embeds\": [{
                \"title\": \"$PAM_USER logged out\",
                \"description\": \"Remote host: $PAM_RHOST\",
                \"color\": 16711680
            }]
        }"
        ;;
esac
if [ -n "$PAYLOAD" ] ; then
    curl -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$WEBHOOK_URL"
fi
