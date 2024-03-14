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
    log self "\"error\":\"HEIMDALL curl failed\"";
    rm $TEMP_FILE
    return 1
  fi
  HEIMDALL_VERSION=$(cat $TEMP_FILE | jq -r .result.node_info.version)
  BLOCK_TIME=$(cat $TEMP_FILE | jq -r .result.sync_info.latest_block_time)
  BLOCK_HEIGHT=$(cat $TEMP_FILE | jq -r .result.sync_info.latest_block_height)
  CATCHING_UP=$(cat $TEMP_FILE | jq -r .result.sync_info.catching_up)
  rm $TEMP_FILE
  log heimdall "\"block_time\":\"$BLOCK_TIME\", \"block_height\":\"$BLOCK_HEIGHT\", \"catching_up\":$CATCHING_UP, \"heimdall_version\":\"$HEIMDALL_VERSION\""
}

fetch_bor() {
  TEMP_FILE=$(mktemp bor-sidecar-bor.XXXXXX)
  if ! curl -sf $BOR_URL --header 'Content-Type: application/json' -d '{"jsonrpc":"2.0", "method":"eth_syncing", "params":[], "id":1}' -o $TEMP_FILE; then
    log self "\"error\":\"BOR curl failed\""
    rm $TEMP_FILE
    return 1
  fi
  BLOCK_CURRENT=$(cat $TEMP_FILE | jq -r .result.currentBlock)
  BLOCK_HIGHEST=$(cat $TEMP_FILE | jq -r .result.highestBlock)
  rm $TEMP_FILE
  log bor "\"block_current\":$(printf "%d" $BLOCK_CURRENT), \"block_highest\":$(printf "%d" $BLOCK_HIGHEST)"
}

while true; do
  fetch_bor
  fetch_heimdall
  sleep $SLEEP
done

# vim: set et ai sts=2 sw=2 :
