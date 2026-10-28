#!/usr/bin/env bash
# Copies the filled-in lines of .env.deploy to this repo's GitHub Actions secrets,
# then (optionally) runs the website deploy. Values are never printed.
#   scripts/push-secrets-to-github.sh             push the secrets
#   scripts/push-secrets-to-github.sh --deploy    push, then run "Deploy web (Vercel)"
#   scripts/push-secrets-to-github.sh --dry-run   only list the names that would be pushed
set -euo pipefail
cd "$(dirname "$0")/.."
file=".env.deploy"
dry=false; deploy=false
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && dry=true
  [ "$arg" = "--deploy" ] && deploy=true
done
[ -f "$file" ] || { echo "$file not found"; exit 1; }

names=()
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  name="${line%%=*}"; value="${line#*=}"
  [ -n "$value" ] || continue
  names+=("$name")
  if ! $dry; then
    printf '%s' "$value" | gh secret set "$name" >/dev/null 2>&1 \
      && echo "set      $name" || echo "FAILED   $name"
  fi
done < "$file"

[ "${#names[@]}" -gt 0 ] || { echo "Nothing filled in yet."; exit 0; }
$dry && { echo "Would push: ${names[*]}"; exit 0; }
if $deploy; then gh workflow run "Deploy web (Vercel)" --ref main && echo "Website deploy started."; fi
