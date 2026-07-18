#!/bin/sh
set -eu

destination=${1:-/root/node22-github-chunks}
repo=$(git rev-parse --show-toplevel)
manifest="$destination/SHA256SUMS.chunks"
compressed_manifest="$destination/SHA256SUMS.compressed"
compressed="$destination/node22-ppc32-20260717.gz"
node="$destination/node22-ppc32-20260717"

test ! -e "$destination"
mkdir "$destination"

git -C "$repo" show HEAD:SHA256SUMS.chunks > "$manifest"
git -C "$repo" show HEAD:SHA256SUMS.compressed > "$compressed_manifest"

while read -r expected part; do
  filename=$(basename "$part")
  temporary="$destination/$filename.partial"
  output="$destination/$filename"
  attempt=1

  while :; do
    rm -f "$temporary"
    if git -C "$repo" show "HEAD:$part" > "$temporary" 2>/dev/null && \
      actual=$(sha256sum "$temporary" | awk '{print $1}') && \
      test "$actual" = "$expected"; then
      mv "$temporary" "$output"
      break
    fi

    rm -f "$temporary"
    if test "$attempt" -ge 5; then
      echo "failed to retrieve $part after $attempt attempts" >&2
      exit 1
    fi
    attempt=$((attempt + 1))
    sleep 2
  done
done < "$manifest"

while read -r _ part; do
  cat "$destination/$(basename "$part")"
done < "$manifest" > "$compressed"

cd "$destination"
sha256sum -c "$compressed_manifest"
gzip -dc "$compressed" > "$node"
printf '%s  %s\n' \
  '84771d769a961b6718bff046bd9f4c10c72b3b2d922efea696aec128ac832fde' \
  "$node" | sha256sum -c -
chmod 755 "$node"
"$node" --version
"$node" -e 'const assert=require("node:assert"); assert.strictEqual(Math.min(5,3,9),3); assert.strictEqual(/a/.test("a"),true); console.log(process.version,process.arch,process.platform);'
