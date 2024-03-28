#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: $0 <json file>"
  exit 1
fi

json=`cat $1`
json=`jq -n "$json"`
echo $json

if [ -z "$BOT_TOKEN" ]; then
  echo "Please set BOT_TOKEN environment variable"
  exit 1
fi

if [ -z "$APPLICATION_ID" ]; then
  echo "Please set APPLICATION_ID environment variable"
  exit 1
fi

curl -v -X PUT -H "Authorization: Bot $BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$json" \
  https://discord.com/api/v10/applications/$APPLICATION_ID/commands
