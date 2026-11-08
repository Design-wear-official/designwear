#!/usr/bin/env bash
# Puts the Gradle distribution the wrapper needs into the wrapper's cache before the build starts.
#
# The wrapper downloads gradle-X-all.zip from services.gradle.org, which redirects to GitHub releases.
# When GitHub answers 504 the whole Android job dies before compiling anything (retrying does not help
# if the outage lasts minutes). This tries the official URL first, then public mirrors, and accepts a
# file ONLY if its SHA-256 equals the checksum Gradle publishes at <distributionUrl>.sha256, so a
# mirror cannot substitute anything. If no source works the script exits 0 and the normal wrapper
# download (and the retry around the build) runs as before.
set -u
cd "$(dirname "$0")/../.."
props=android/gradle/wrapper/gradle-wrapper.properties
url=$(grep '^distributionUrl=' "$props" | cut -d= -f2- | sed 's#\\:#:#g')
[ -n "$url" ] || { echo "no distributionUrl in $props; nothing to seed"; exit 0; }
name=$(basename "$url"); dist=${name%.zip}
hash=$(URL="$url" python3 - <<'PY'
import hashlib, os
n = int(hashlib.md5(os.environ["URL"].encode()).hexdigest(), 16)
d = "0123456789abcdefghijklmnopqrstuvwxyz"; s = ""
while n: n, r = divmod(n, 36); s = d[r] + s
print(s or "0")
PY
)
dir="${GRADLE_USER_HOME:-$HOME/.gradle}/wrapper/dists/$dist/$hash"
if [ -f "$dir/$name.ok" ] || [ -f "$dir/$name" ]; then echo "$name already in $dir"; exit 0; fi

expected=$(curl -fsSL --retry 3 --connect-timeout 20 "$url.sha256" 2>/dev/null | tr -d '[:space:]')
if ! printf '%s' "$expected" | grep -Eq '^[0-9a-f]{64}$'; then
  echo "::warning::could not read the published checksum for $name; leaving the download to the wrapper"
  exit 0
fi

mkdir -p "$dir"
tmp="$dir/$name.part"
for src in "$url" "https://mirrors.cloud.tencent.com/gradle/$name" "https://repo.huaweicloud.com/gradle/$name"; do
  echo "::group::trying $src"
  rm -f "$tmp"
  if curl -fL --retry 2 --connect-timeout 20 --max-time 900 -o "$tmp" "$src"; then
    actual=$(sha256sum "$tmp" | cut -d' ' -f1)
    if [ "$actual" = "$expected" ]; then
      mv "$tmp" "$dir/$name"; echo "::endgroup::"
      echo "seeded $dir/$name from $src (sha256 verified)"; exit 0
    fi
    echo "checksum mismatch from $src (got $actual); discarding"
  fi
  echo "::endgroup::"
done
rm -f "$tmp"
echo "::warning::no source worked; leaving the download to the wrapper"
exit 0
