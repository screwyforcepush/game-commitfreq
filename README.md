# game-commitfreq

A project that games commit-frequency metrics.

Some third-party scrapers treat commit count and commit cadence as a proxy
for engineering activity — and, increasingly, for "agentic engineering
prowess." It is a poor proxy. This repo demonstrates how poor by generating
a continuous stream of randomised commits that satisfy the metric without
producing any actual engineering output.

## How it works

- `commit-spam.sh` makes N commits in one batch, then pushes once. Each
  commit performs a randomly chosen operation (create / append / modify /
  trim / rename / delete) on files inside `scratch/`. Commit messages are
  assembled from random verbs, nouns, and prefixes. A configurable jitter
  (`SLEEP_MIN`/`SLEEP_MAX`, default 5–20s) spaces commits within a batch.
- `loop.sh [commits_per_day]` runs `commit-spam.sh` forever. The arg
  (default 6500) drives two derived ranges:
  - per-commit sleep: mean `86400 / target`, jittered ±50%
  - batch size (commits per push): `[target/20, target/10]`, so push
    frequency stays at ~10–20 per day regardless of the commit target
- Output from the loop is written to `scratch/loop.log`, which is itself
  swept into commits. The op picker explicitly skips it so it is never
  modified or deleted mid-write.

## Running it

```sh
./commit-spam.sh 50                              # one batch of 50, push, exit
nohup ./loop.sh > scratch/loop.log 2>&1 &       # default ~6500/day
nohup ./loop.sh 10000 > scratch/loop.log 2>&1 & # ~10k/day
```

Author identity is taken from the local git config. To stop the loop:
`kill <pid>`.

## Why this exists

If a metric can be moved by a shell script, it is not measuring what its
users think it is measuring. Treat any "commits per day" leaderboard
accordingly.
