#!/usr/bin/env bash
set -euo pipefail

VOTE_URL="${VOTE_URL:-http://localhost:8080}"
RESULT_URL="${RESULT_URL:-http://localhost:8081}"

echo "Waiting for voting application..."

for i in $(seq 1 60); do
  if curl -fsS "$VOTE_URL" -o /dev/null; then
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "Voting application did not become ready"
    exit 1
  fi
  sleep 2
done

echo "Checking current vote count..."

get_vote_count() {
  docker compose exec -T db psql -U postgres -d postgres -t -A \
    -c "SELECT COUNT(*) FROM votes WHERE vote = 'b';"
}

BEFORE=$(get_vote_count)

echo "Submitting a test vote..."

curl -fsS -X POST \
  --data "vote=b" \
  "$VOTE_URL" -o /dev/null

echo "Waiting for results application..."

for i in $(seq 1 60); do
  if curl -fsS "$RESULT_URL" -o /dev/null; then
    echo "Results application is responding"
    echo "Checking that the vote was counted..."

    for attempt in $(seq 1 30); do
      AFTER=$(get_vote_count)

      if [ "$AFTER" -gt "$BEFORE" ]; then
        echo "Integration test passed: vote count increased from $BEFORE to $AFTER"
        exit 0
      fi

      sleep 2
    done

    echo "Test failed: vote count did not increase"
    exit 1
  fi
  sleep 2
done

echo "Results application did not become ready"
exit 1
