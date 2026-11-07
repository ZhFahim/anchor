#!/bin/sh
# Starts an image on empty data and checks that it works, before and after a restart with a live sync stream.
#   sh docker/test-image.sh <image>
set -eu

IMAGE="$1"
CONTAINER="anchor-image-test"
PORT="${PORT:-3099}"
TIMEOUT="${TIMEOUT:-120}"
URL="http://localhost:$PORT"
CREDENTIALS='"email":"image-test@example.com","password":"Image-test-12345"'

cleanup() {
  docker rm -fv "$CONTAINER" >/dev/null 2>&1 || true
}

fail() {
  echo "[image-test] FAILED: $1"
  docker logs --tail 50 "$CONTAINER" 2>&1 || true
  exit 1
}

wait_until_ready() {
  waited=0
  until curl -fs -o /dev/null "$URL/api/health"; do
    [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" = "true" ] || fail "the container stopped"
    [ "$waited" -lt "$TIMEOUT" ] || fail "not healthy after ${TIMEOUT}s"
    sleep 2
    waited=$((waited + 2))
  done
}

post() {
  curl -fsS -o /dev/null -X POST -H "Content-Type: application/json" -d "$2" "$URL$1"
}

cleanup
trap cleanup EXIT
docker run -d --name "$CONTAINER" -p "$PORT:3000" "$IMAGE" >/dev/null

wait_until_ready
curl -fsS -o /dev/null "$URL/login" || fail "the login page did not load"
post /api/auth/register "{$CREDENTIALS,\"name\":\"Image test\"}" || fail "could not register"
TOKEN=$(curl -fsS -X POST -H "Content-Type: application/json" -d "{$CREDENTIALS}" "$URL/api/auth/login" | sed -E 's/.*"access_token":"([^"]+)".*/\1/')
[ -n "$TOKEN" ] || fail "could not sign in"
curl -fsN -o /dev/null -H "Authorization: Bearer $TOKEN" "$URL/api/sync/events" &
SYNC_STREAM=$!
sleep 1
kill -0 "$SYNC_STREAM" 2>/dev/null || fail "could not open the sync stream"

docker restart "$CONTAINER" >/dev/null
wait_until_ready
if docker logs "$CONTAINER" 2>&1 | grep -q "not properly shut down"; then
  fail "Postgres did not shut down cleanly"
fi
post /api/auth/login "{$CREDENTIALS}" || fail "could not sign in after a restart"

echo "[image-test] passed"
