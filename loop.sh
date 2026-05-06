#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")"

# Usage: ./loop.sh [commits_per_day]
# Default ~6500/day. The arg controls the per-commit sleep range;
# batch size (push frequency) is independent and stays at 150-300.
TARGET_PER_DAY="${1:-6500}"

MEAN_SLEEP=$(( 86400 / TARGET_PER_DAY ))
(( MEAN_SLEEP < 1 )) && MEAN_SLEEP=1

SLEEP_MIN=$(( MEAN_SLEEP / 2 ))
SLEEP_MAX=$(( (MEAN_SLEEP * 3) / 2 ))
(( SLEEP_MIN < 1 )) && SLEEP_MIN=1
(( SLEEP_MAX < SLEEP_MIN )) && SLEEP_MAX=$SLEEP_MIN
export SLEEP_MIN SLEEP_MAX

echo "[$(date -Is)] target ${TARGET_PER_DAY}/day, sleep ${SLEEP_MIN}-${SLEEP_MAX}s, batch 150-300"

while true; do
  count=$((150 + RANDOM % 151))
  ./commit-spam.sh "$count" || echo "[$(date -Is)] batch failed; continuing" >&2
done
