#!/bin/sh
# Checks that a server can go back to upstream Anchor, and then to Anchor+
# again, keeping its notes: fills an Anchor+ server with everything only
# Anchor+ has (a file, a frozen, locked and invisible note, a share link),
# starts upstream's image on its data and checks that it signs in, lists and
# syncs, then starts the Anchor+ image again and checks nothing was lost.
#   sh docker/test-switch-back.sh <image> [upstream image]
# With PREVIOUS=<image>, the data is made on that release first and then
# brought up to date by <image>, so its migrations run on real data too.
set -eu

IMAGE="$1"
UPSTREAM="${2:-ghcr.io/zhfahim/anchor:latest}"
PREVIOUS="${PREVIOUS:-}"
CONTAINER="anchor-switch-test"
VOLUME="anchor-switch-test"
PORT="${PORT:-3098}"
TIMEOUT="${TIMEOUT:-120}"
URL="http://localhost:$PORT"
CREDENTIALS='"email":"switch-test@example.com","password":"Switch-test-12345"'

cleanup() {
  docker rm -fv "$CONTAINER" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
  [ -z "${WORK:-}" ] || rm -rf "$WORK"
}

# jq, without the carriage returns it prints on Windows.
jq() {
  command jq "$@" | tr -d '\r'
}

fail() {
  echo "[switch-test] FAILED: $1"
  docker logs --tail 50 "$CONTAINER" 2>&1 || true
  exit 1
}

start() {
  echo "[switch-test] starting $1"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker run -d --name "$CONTAINER" -p "$PORT:3000" \
    -e PG_USER=anchor -e PG_PASSWORD=password -e PG_DATABASE=anchor \
    -v "$VOLUME:/data" "$1" >/dev/null
  waited=0
  until curl -fs -o /dev/null "$URL/api/health"; do
    [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" = "true" ] || fail "$1 stopped"
    [ "$waited" -lt "$TIMEOUT" ] || fail "$1 not healthy after ${TIMEOUT}s"
    sleep 2
    waited=$((waited + 2))
  done
}

stop() {
  docker stop -t 60 "$CONTAINER" >/dev/null
}

sign_in() {
  TOKEN=$(curl -fsS -X POST -H "Content-Type: application/json" \
    -d "{$CREDENTIALS}" "$URL/api/auth/login" | jq -r .access_token) ||
    fail "could not sign in"
}

# api <method> <path> [json]: prints the response, fails on an error status.
api() {
  curl -fsS -X "$1" -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" ${3:+-d "$3"} "$URL$2"
}

# upload <note id> <file in $WORK> <type>: prints the attachment's id.
upload() {
  (cd "$WORK" && curl -fsS -H "Authorization: Bearer $TOKEN" \
    -F "file=@$2;type=$3" "$URL/api/notes/$1/attachments") | jq -r .id
}

# Every note and attachment can be read, and a full sync goes through.
check_readable() {
  api GET /api/notes >"$WORK/notes.json" || fail "$1: could not list notes"
  for id in $(jq -r '.[].id' "$WORK/notes.json"); do
    api GET "/api/notes/$id/attachments" >/dev/null ||
      fail "$1: could not list the attachments of note $id"
  done
  cursor=""
  while :; do
    api POST /api/sync "{\"changes\":[]${cursor:+,\"cursor\":\"$cursor\"}}" \
      >"$WORK/sync.json" || fail "$1: could not sync"
    [ "$(jq -r .hasMore "$WORK/sync.json")" = "true" ] || break
    cursor=$(jq -r .nextCursor "$WORK/sync.json")
  done
}

cleanup
trap cleanup EXIT
WORK="$(mktemp -d)"
docker volume create "$VOLUME" >/dev/null

# 1. Anchor+, with everything upstream doesn't have.
start "${PREVIOUS:-$IMAGE}"
curl -fsS -o /dev/null -X POST -H "Content-Type: application/json" \
  -d "{$CREDENTIALS,\"name\":\"Switch test\"}" "$URL/api/auth/register" ||
  fail "could not register"
sign_in
printf '%%PDF-1.4\n%%%%EOF\n' >"$WORK/deed.pdf"
printf '\211PNG\r\n\032\n' >"$WORK/pixel.png"
note() { api POST /api/notes "{\"title\":\"$1\"}" | jq -r .id; }
FILES=$(note files)
FILE=$(upload "$FILES" deed.pdf application/pdf)
PICTURE=$(upload "$FILES" pixel.png image/png)
FROZEN=$(note frozen)
api PATCH "/api/notes/$FROZEN/freeze" '{"isFrozen":true}' >/dev/null
LOCKED=$(note locked)
api PATCH "/api/notes/$LOCKED/lock" '{"lock":"tap"}' >/dev/null
INVISIBLE=$(note invisible)
api PATCH "/api/notes/$INVISIBLE/invisible" '{"isInvisible":true}' >/dev/null
api PUT "/api/notes/$FILES/link" '{"permission":"viewer"}' >/dev/null 2>&1 ||
  echo "[switch-test] (no share links in ${PREVIOUS:-$IMAGE})"

if [ -n "$PREVIOUS" ]; then
  stop
  start "$IMAGE"
  sign_in
  check_readable "$IMAGE after $PREVIOUS"
fi

# What Anchor+ tells an admin before switching.
docker exec "$CONTAINER" switch-check >"$WORK/check.txt" 2>&1 ||
  { cat "$WORK/check.txt"; fail "switch-check refused"; }
grep -q "1 files attached" "$WORK/check.txt" ||
  { cat "$WORK/check.txt"; fail "switch-check didn't count the file"; }
sed 's/^/[switch-check] /' "$WORK/check.txt"
stop

# 2. Upstream Anchor on the same data.
start "$UPSTREAM"
sign_in
check_readable "$UPSTREAM"
[ "$(jq length "$WORK/notes.json")" -ge 3 ] || fail "$UPSTREAM lists too few notes"
api GET "/api/notes/$FILES/attachments" | jq -e --arg id "$PICTURE" \
  'map(.id) == [$id]' >/dev/null || fail "$UPSTREAM doesn't list the picture"
# Changes made there come back to Anchor+: Anchor+'s columns don't get in
# the way of upstream's writes.
api PATCH "/api/notes/$LOCKED" '{"title":"edited upstream"}' >/dev/null ||
  fail "could not edit a note on $UPSTREAM"
MADE=$(note "made upstream") || fail "could not make a note on $UPSTREAM"
MADE_PICTURE=$(upload "$MADE" pixel.png image/png) ||
  fail "could not attach a picture on $UPSTREAM"
stop

# 3. Back to Anchor+: everything it had is still there.
start "$IMAGE"
sign_in
check_readable "$IMAGE after $UPSTREAM"
api GET "/api/notes/$FILES/attachments" | jq -e --arg f "$FILE" --arg p "$PICTURE" \
  'any(.[]; .id == $f and .type == "file") and any(.[]; .id == $p and .type == "image")' \
  >/dev/null || fail "the file or the picture is gone"
api GET "/api/notes/$FROZEN" | jq -e '.isFrozen == true' >/dev/null ||
  fail "the frozen note isn't frozen any more"
api GET "/api/notes/$LOCKED" | jq -e '.title == "edited upstream" and .lock == "tap"' \
  >/dev/null || fail "the locked note lost its lock or the upstream edit"
api GET "/api/notes/$INVISIBLE" | jq -e '.isInvisible == true' >/dev/null ||
  fail "the invisible note is visible"
api GET "/api/notes/$MADE/attachments" | jq -e --arg p "$MADE_PICTURE" \
  'map(.id) == [$p]' >/dev/null || fail "the note made upstream lost its picture"

echo "[switch-test] passed"
