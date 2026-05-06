#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")"

# Usage: ./loop.sh [commits_per_day]
# Default ~6500/day. Sleep range is derived to hit the commit target;
# batch size is derived to keep pushes at ~10-20 per day.
TARGET_PER_DAY="${1:-6500}"

MEAN_SLEEP=$(( 86400 / TARGET_PER_DAY ))
(( MEAN_SLEEP < 1 )) && MEAN_SLEEP=1

SLEEP_MIN=$(( MEAN_SLEEP / 2 ))
SLEEP_MAX=$(( (MEAN_SLEEP * 3) / 2 ))
(( SLEEP_MIN < 1 )) && SLEEP_MIN=1
(( SLEEP_MAX < SLEEP_MIN )) && SLEEP_MAX=$SLEEP_MIN
export SLEEP_MIN SLEEP_MAX

BATCH_MIN=$(( TARGET_PER_DAY / 20 ))
BATCH_MAX=$(( TARGET_PER_DAY / 10 ))
(( BATCH_MIN < 1 )) && BATCH_MIN=1
(( BATCH_MAX < BATCH_MIN )) && BATCH_MAX=$BATCH_MIN

echo "[$(date -Is)] target ${TARGET_PER_DAY}/day, sleep ${SLEEP_MIN}-${SLEEP_MAX}s, batch ${BATCH_MIN}-${BATCH_MAX}"

while true; do
  count=$(( BATCH_MIN + RANDOM % (BATCH_MAX - BATCH_MIN + 1) ))
  ./commit-spam.sh "$count" || echo "[$(date -Is)] batch failed; continuing" >&2
done
