#!/usr/bin/env bash
# Runs a command up to N times, waiting longer after each failure.
# Used for steps that download from third-party hosts (the Gradle distribution comes from GitHub
# releases and now and then answers 504). A genuine build error still fails after the last attempt.
#
#   .github/scripts/retry.sh 4 flutter build apk --debug ...
set -u
attempts="$1"; shift
n=1
while true; do
  echo "::group::attempt ${n} of ${attempts}: $*"
  "$@"; status=$?
  echo "::endgroup::"
  if [ "$status" -eq 0 ]; then exit 0; fi
  if [ "$n" -ge "$attempts" ]; then
    echo "::error::failed after ${attempts} attempts (exit ${status}): $*"
    exit "$status"
  fi
  wait=$((n * 30))
  echo "::warning::attempt ${n} failed (exit ${status}); retrying in ${wait}s"
  sleep "$wait"
  n=$((n + 1))
done
