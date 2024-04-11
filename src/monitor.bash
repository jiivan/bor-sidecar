#!/bin/bash

SLEEP=${SLEEP:-600}
HEIMDALL_URL=${HEIMDALL_URL:-"http://localhost:26657/status"}
BOR_URL=${BOR_URL:-"http://localhost:8545/"}
#HEIMDALL_URL="http://polygon_heimdall_daemon-bor-1:26657/status"
#BOR_URL="http://polygon_bor-bor-1:8545/"

log() {
  echo "{\"datetime\":\"$(date -u -Ins)\", \"type\":\"$1\", \"version\":\"$APP_VERSION\", $2}" > /dev/stderr
}

log self "\"SLEEP\": \"$SLEEP\", \"HEIMDALL_URL\": \"$HEIMDALL_URL\", \"BOR_URL\": \"$BOR_URL\""

fetch_heimdall() {
  TEMP_FILE=$(mktemp bor-sidecar-heimdall.XXXXXX)
  if ! curl -sf $HEIMDALL_URL -o $TEMP_FILE; then
    log self "\"error\":\"HEIMDALL curl failed\", \"url\":\"$HEIMDALL_URL\"";
    rm $TEMP_FILE
    return 1
  fi
  HEIMDALL_VERSION=$(cat $TEMP_FILE | jq -r .result.node_info.version)
  BLOCK_TIME=$(cat $TEMP_FILE | jq -r .result.sync_info.latest_block_time)
  BLOCK_HEIGHT=$(cat $TEMP_FILE | jq -r .result.sync_info.latest_block_height)
  CATCHING_UP=$(cat $TEMP_FILE | jq -r .result.sync_info.catching_up)
  rm $TEMP_FILE
  log heimdall "\"block_time\":\"$BLOCK_TIME\", \"block_height\":\"$BLOCK_HEIGHT\", \"catching_up\":$CATCHING_UP, \"heimdall_version\":\"$HEIMDALL_VERSION\", \"url\":\"$HEIMDALL_URL\""
}

fetch_bor() {
  TEMP_FILE=$(mktemp bor-sidecar-bor.XXXXXX)
  if ! curl -sf $BOR_URL --header 'Content-Type: application/json' -d '{"jsonrpc":"2.0", "method":"eth_getBlockByNumber", "params":["latest", false], "id":1}' -o $TEMP_FILE; then
    log self "\"error\":\"BOR curl failed\", \"url\":\"$BOR_URL\""
    rm $TEMP_FILE
    return 1
  fi
  TIMESTAMP=$(date +%s)
  BLOCK_CURRENT=$(cat $TEMP_FILE | jq -r .result.number)
  BLOCK_TIMESTAMP=$(cat $TEMP_FILE | jq -r .result.timestamp)
  rm $TEMP_FILE
  BLOCK_TIMESTAMP_DECIMAL=$(printf "%d" $BLOCK_TIMESTAMP)
  BLOCK_AGE=$((TIMESTAMP-BLOCK_TIMESTAMP_DECIMAL))
  log bor "\"block_current\":$(printf "%d" $BLOCK_CURRENT), \"block_age\":$BLOCK_AGE, \"url\":\"$BOR_URL\""
}

while true; do
  fetch_bor
  fetch_heimdall
  sleep $SLEEP
done

# vim: set et ai sts=2 sw=2 :
