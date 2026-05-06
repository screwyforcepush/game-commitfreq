#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

COUNT="${1:-10}"
SCRATCH="scratch"
SLEEP_MIN="${SLEEP_MIN:-5}"
SLEEP_MAX="${SLEEP_MAX:-20}"
mkdir -p "$SCRATCH"

WORDS=(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu nimbus prism cobalt ember solstice harbor lattice)
VERBS=(tweak update refactor adjust polish nudge bump tidy wire rework cleanup tune trim seed expand prune)
PREFIXES=("" "" "" "wip: " "chore: " "fix: " "refactor: " "docs: " "build: " "feat: ")
EXTS=(txt md log dat csv)

pick() { local -n _arr=$1; printf '%s' "${_arr[RANDOM % ${#_arr[@]}]}"; }
token() { od -An -N3 -tx1 /dev/urandom | tr -d ' \n'; }
random_line() { printf '%s %s %s\n' "$(pick VERBS)" "$(pick WORDS)" "$(token)"; }
list_files() { find "$SCRATCH" -type f 2>/dev/null; }

op_create() {
  local name="$SCRATCH/$(pick WORDS)-$(token).$(pick EXTS)"
  local n=$((1 + RANDOM % 6))
  for ((i = 0; i < n; i++)); do random_line; done > "$name"
  printf 'create %s' "$(basename "$name")"
}

op_append() {
  local f; f=$(list_files | shuf -n 1)
  [[ -z "$f" ]] && { op_create; return; }
  local n=$((1 + RANDOM % 4))
  for ((i = 0; i < n; i++)); do random_line; done >> "$f"
  printf 'append %s' "$(basename "$f")"
}

op_modify() {
  local f; f=$(list_files | shuf -n 1)
  [[ -z "$f" ]] && { op_create; return; }
  local lines; lines=$(wc -l < "$f")
  if [[ $lines -lt 1 ]]; then
    random_line >> "$f"
    printf 'seed %s' "$(basename "$f")"
    return
  fi
  local target=$((1 + RANDOM % lines))
  local replacement; replacement=$(random_line)
  sed -i "${target}s|.*|${replacement}|" "$f"
  printf 'modify %s:%d' "$(basename "$f")" "$target"
}

op_delete_line() {
  local f; f=$(list_files | shuf -n 1)
  [[ -z "$f" ]] && { op_create; return; }
  local lines; lines=$(wc -l < "$f")
  if [[ $lines -lt 2 ]]; then op_append; return; fi
  local target=$((1 + RANDOM % lines))
  sed -i "${target}d" "$f"
  printf 'trim %s:%d' "$(basename "$f")" "$target"
}

op_rename() {
  local f; f=$(list_files | shuf -n 1)
  [[ -z "$f" ]] && { op_create; return; }
  local newname="$SCRATCH/$(pick WORDS)-$(token).$(pick EXTS)"
  git mv "$f" "$newname"
  printf 'rename %s -> %s' "$(basename "$f")" "$(basename "$newname")"
}

op_delete() {
  local count; count=$(list_files | wc -l)
  if [[ $count -lt 3 ]]; then op_create; return; fi
  local f; f=$(list_files | shuf -n 1)
  git rm -q "$f"
  printf 'drop %s' "$(basename "$f")"
}

OPS=(op_create op_create op_append op_append op_append op_modify op_modify op_delete_line op_delete_line op_rename op_delete op_delete)

random_message() {
  local prefix; prefix=$(pick PREFIXES)
  local body
  case $((RANDOM % 5)) in
    0) body="$(pick VERBS) $(pick WORDS)" ;;
    1) body="$(pick VERBS) $(pick WORDS) $(pick WORDS)" ;;
    2) body="$(pick VERBS) $(pick WORDS) for $(pick WORDS)" ;;
    3) body="$(pick WORDS) $(pick VERBS)s" ;;
    4) body="$(pick VERBS) $(pick WORDS) ($(token))" ;;
  esac
  printf '%s%s' "$prefix" "$body"
}

for ((i = 1; i <= COUNT; i++)); do
  op="${OPS[RANDOM % ${#OPS[@]}]}"
  detail=$("$op")
  git add -A "$SCRATCH"
  if git diff --cached --quiet; then continue; fi
  msg="$(random_message)"
  git commit -q -m "$(printf '%s\n\n%s\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\n' "$msg" "$detail")"
  printf '%2d/%d  %-44s  %s\n' "$i" "$COUNT" "$msg" "$detail"
  if (( i < COUNT )); then
    sleep $((SLEEP_MIN + RANDOM % (SLEEP_MAX - SLEEP_MIN + 1)))
  fi
done

git push
