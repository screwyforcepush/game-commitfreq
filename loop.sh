#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")"

# Per-batch jitter: 150-300 commits.
# With commit-spam.sh defaults (5-20s sleep between commits, mean 12.5s):
#   batch duration  ~30-65 min
#   pushes per day  ~25-30
#   commits per day ~5500-7500
while true; do
  count=$((150 + RANDOM % 151))
  ./commit-spam.sh "$count" || echo "[$(date -Is)] batch failed; continuing" >&2
done
