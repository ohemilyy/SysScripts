#!/bin/bash

DISCORD_WEBHOOK_URL=""

LOG_FILE="/opt/hydrabank/logs/mal.txt"

clamscan -r / > "$LOG_FILE"

THREAT_COUNT=$(grep -o "Infected files: [1-9][0-9]*" "$LOG_FILE" | awk '{print $3}')

TMP_PAYLOAD_FILE=$(mktemp)

cat <<EOF > "$TMP_PAYLOAD_FILE"
{
  "embeds": [
    {
      "title": "ClamAV Scan Results",
      "color": 16711680,
      "description": "ClamAV detected $THREAT_COUNT threats.",
      "fields": [
        {
          "name": "Detailed Results",
          "value": "Results are attached as a text file."
        }
      ]
    }
  ]
}
EOF

curl -H "Content-Type: application/json" -X POST --data @"$TMP_PAYLOAD_FILE" "$DISCORD_WEBHOOK_URL"

curl -X POST -H "Content-Type: multipart/form-data" -F "file=@$LOG_FILE" "$DISCORD_WEBHOOK_URL"

rm "$TMP_PAYLOAD_FILE"
