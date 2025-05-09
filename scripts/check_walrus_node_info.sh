#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <NODE_ID>"
  exit 1
fi

NODE_ID=$1
RAW_JSON=$(sui client object $NODE_ID --json 2>/dev/null)

# === On-chain fields ===
NODE_NAME=$(echo "$RAW_JSON" | jq -r '.content.fields.node_info.fields.name')
NODE_ADDRESS=$(echo "$RAW_JSON" | jq -r '.content.fields.node_info.fields.network_address')
WAL_BALANCE=$(echo "$RAW_JSON" | jq -r '.content.fields.wal_balance')
REWARDS_POOL=$(echo "$RAW_JSON" | jq -r '.content.fields.rewards_pool')
COMMISSION_RATE_BPS=$(echo "$RAW_JSON" | jq -r '.content.fields.commission_rate')
CAPACITY_BYTES=$(echo "$RAW_JSON" | jq -r '.content.fields.voting_params.fields.node_capacity')
EPOCH=$(echo "$RAW_JSON" | jq -r '.content.fields.latest_epoch')

# === Conversion ===
WAL_BALANCE_TO_WAL=$(echo "scale=6; $WAL_BALANCE / 1000000000" | bc)
REWARDS_POOL_TO_WAL=$(echo "scale=6; $REWARDS_POOL / 1000000000" | bc)
COMMISSION_PERCENT=$(echo "scale=2; $COMMISSION_RATE_BPS / 100" | bc)
CAPACITY_TB=$(echo "scale=2; $CAPACITY_BYTES / 1000000000000" | bc)

# === Runtime Info via /v1/health ===
NODE_HOST=$(echo "$NODE_ADDRESS" | cut -d':' -f1)
NODE_PORT=$(echo "$NODE_ADDRESS" | cut -d':' -f2)
HEALTH_URL="https://$NODE_HOST:$NODE_PORT/v1/health"
HEALTH_JSON=$(curl -sk "$HEALTH_URL")

UPTIME_SECS=$(echo "$HEALTH_JSON" | jq -r '.success.data.uptime.secs')
STATUS=$(echo "$HEALTH_JSON" | jq -r '.success.data.nodeStatus')
SHARDS=$(echo "$HEALTH_JSON" | jq -r '.success.data.shardSummary.owned')
RUNTIME_EPOCH=$(echo "$HEALTH_JSON" | jq -r '.success.data.epoch')

# Convert uptime to human-readable (e.g., 12d 5h 30m)
DAYS=$((UPTIME_SECS / 86400))
HOURS=$(( (UPTIME_SECS % 86400) / 3600 ))
UPTIME_FORMATTED="${DAYS}d ${HOURS}h"

# === Output ===
echo ""
echo "Staking Pool Summary"
echo "--------------------------------------------"
echo "Node Name         : $NODE_NAME"
echo "Node ID           : $NODE_ID"
echo "Epoch             : $EPOCH"
echo "Total WAL Balance : $WAL_BALANCE_TO_WAL WAL"
echo "Rewards Pool      : $REWARDS_POOL_TO_WAL WAL"
echo "Commission Rate   : $COMMISSION_PERCENT%"
echo "Capacity          : $CAPACITY_TB TB"
echo ""
echo "Node Runtime Info"
echo "--------------------------------------------"
echo "Status            : $STATUS"
echo "Uptime            : $UPTIME_FORMATTED"
echo "Shards Owned      : $SHARDS"
echo "Reported Epoch    : $RUNTIME_EPOCH"