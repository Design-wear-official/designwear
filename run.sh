#!/usr/bin/env bash
# Interactive flavor picker for `flutter run`.
# Usage: ./run.sh [extra flutter run args...]
set -euo pipefail

echo "Select flavor:"
echo "[1]: internal"
echo "[2]: external"
read -rp "Please choose one (or \"q\" to quit): " choice

case "$choice" in
  1) flavor="internal" ;;
  2) flavor="external" ;;
  q|Q) exit 0 ;;
  *) echo "Invalid choice: $choice" >&2; exit 1 ;;
esac

# .env and .env.local are bundled as assets. An empty (zero-byte) asset makes
# Flutter's web dev server log "Bad state: No element", so give them a comment.
for f in .env .env.local; do
  [ -s "$f" ] || printf '# local settings (see .env.example)\n' > "$f"
done

echo
echo "Select device:"
echo "[1]: Linux desktop"
echo "[2]: let flutter choose (prompts if more than one device is attached)"
echo "[3]: Web in your own browser (use this if Chrome fails to launch)"
read -rp "Please choose one (or \"q\" to quit): " device_choice

device_args=()
web=false
case "$device_choice" in
  1) device_args=(-d linux) ;;
  2) ;;
  3)
    # First free port from 8081 up (8080 is often taken by Jenkins or a CMS
    # gateway). Override with WEB_PORT=9000 ./run.sh
    web_port="${WEB_PORT:-8081}"
    while ss -ltn 2>/dev/null | grep -qE ":${web_port}\b"; do web_port=$((web_port + 1)); done
    device_args=(-d web-server --web-port "$web_port" --web-hostname localhost)
    web=true
    ;;
  q|Q) exit 0 ;;
  *) echo "Invalid choice: $device_choice" >&2; exit 1 ;;
esac

echo "Launching lib/main.dart with FLAVOR=$flavor..."
# --dart-define=FLAVOR picks which lib/flavours/<flavor>/ config
# is used (see lib/flavours/flavour_selector.dart). --flavor selects the matching Android Gradle product
# flavor (android/app/build.gradle.kts), which gives internal its own
# applicationId — a real, separately-installable app, not just a different
# banner in the same APK. Both must be passed and must agree.
# The app loads products, accounts and orders through the DesignWear API. When
# DESIGNWEAR_API_URL points at this machine and nothing is listening there,
# start the API (from ../designwear-server) for the length of this run.
api_pid=""
start_api_if_needed() {
  local url host port
  url=$(grep -E '^DESIGNWEAR_API_URL=' .env 2>/dev/null | head -1 | cut -d= -f2-)
  [[ "$url" =~ ^http://(localhost|127\.0\.0\.1):([0-9]+)/?$ ]] || return 0
  host="${BASH_REMATCH[1]}"; port="${BASH_REMATCH[2]}"
  if ss -ltn 2>/dev/null | grep -qE ":${port}\b"; then
    echo "API already running on $host:$port"
    return 0
  fi
  local dir="../designwear-server"
  if [ ! -f "$dir/src/index.js" ]; then
    echo "DESIGNWEAR_API_URL is $url but $dir was not found; the app will use the CMS directly." >&2
    return 0
  fi
  echo "Starting the DesignWear API on port $port..."
  ( set -a; . ./.env; set +a
    cd "$dir" && PORT="$port" SETHUCMS_URL="$SETHUCMS_URL" SETHUCMS_CONNECTION_ID="$SETHUCMS_CONNECTION_ID" \
      SETHUCMS_TOKEN="$SETHUCMS_VIEWER_TOKEN" exec node src/index.js ) > "${TMPDIR:-/tmp}/designwear-api.log" 2>&1 &
  api_pid=$!
  for _ in $(seq 1 20); do
    curl -fs "$url/v1/health" >/dev/null 2>&1 && { echo "API is up (log: ${TMPDIR:-/tmp}/designwear-api.log)"; return 0; }
    sleep 0.5
  done
  echo "The API did not start; see ${TMPDIR:-/tmp}/designwear-api.log" >&2
}
trap '[ -n "$api_pid" ] && kill "$api_pid" 2>/dev/null' EXIT
start_api_if_needed

# --flavor only exists for Android, iOS, macOS, Linux and Windows; on web the
# flavour comes from --dart-define alone.
if $web; then
  echo "Open http://localhost:${web_port} in your browser once it says it is serving."
  flutter run --dart-define=FLAVOR="$flavor" "${device_args[@]}" "$@"
  exit $?
fi
flutter run --flavor "$flavor" --dart-define=FLAVOR="$flavor" "${device_args[@]}" "$@"
