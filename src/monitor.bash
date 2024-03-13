#!/bin/bash

#HEIMDALL_URL="http://polygon_heimdall_daemon-bor-1:26657/status"
#HEIMDALL_URL="http://localhost:26657/status"
#BOR_URL="http://polygon_bor-bor-1:8545/"

log() {
  echo "{\"datetime\":\"$(date -u --iso-8601=ns)\", \"type\":\"$1\", \"version\":\"$APP_VERSION\", $2}" > /dev/stderr
}

fetch_heimdall() {
  TEMP_FILE=$(mktemp bor-sidecar-heimdall.XXXX)
  curl -s $HEIMDALL_URL|jq .result > $TEMP_FILE
  HEIMDALL_VERSION=$(cat $TEMP_FILE | jq -r .node_info.version)
  BLOCK_TIME=$(cat $TEMP_FILE | jq -r .sync_info.latest_block_time)
  BLOCK_HEIGHT=$(cat $TEMP_FILE | jq -r .sync_info.latest_block_height)
  CATCHING_UP=$(cat $TEMP_FILE | jq -r .sync_info.catching_up)
  rm $TEMP_FILE
  log heimdall "\"block_time\":\"$BLOCK_TIME\", \"block_height\":\"$BLOCK_HEIGHT\", \"catching_up\":$CATCHING_UP, \"heimdall_version\":\"$HEIMDALL_VERSION\""
}

fetch_bor() {
  TEMP_FILE=$(mktemp bor-sidecar-bor.XXXX)
  curl -s $BOR_URL --header 'Content-Type: application/json' -d '{"jsonrpc":"2.0", "method":"eth_syncing", "params":[], "id":1}'|jq .result > $TEMP_FILE
  BLOCK_CURRENT=$(cat $TEMP_FILE | jq -r .currentBlock)
  BLOCK_HIGHEST=$(cat $TEMP_FILE | jq -r .highestBlock)
  rm $TEMP_FILE
  log bor "\"block_current\":$(printf "%d" $BLOCK_CURRENT), \"block_highest\":$(printf "%d" $BLOCK_HIGHEST)"
}

while true; do
  fetch_bor
  fetch_heimdall
  sleep 600
done

# vim: set et ai sts=2 sw=2 :
