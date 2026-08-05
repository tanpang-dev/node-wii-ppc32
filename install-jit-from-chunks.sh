#!/bin/sh
set -eu

release=node-v22.11.0-wii-ppc32-jit-r1
destination=${1:-/root/node22-jit-r1}
repo=$(git rev-parse --show-toplevel)
chunk_manifest="SHA256SUMS.$release.chunks"
compressed_manifest="SHA256SUMS.$release.compressed"
binary_manifest="SHA256SUMS.$release"
compressed="$destination/$release.gz"
node="$destination/$release"

test ! -e "$destination"
mkdir "$destination"

git -C "$repo" show "HEAD:$chunk_manifest" > "$destination/$chunk_manifest"
git -C "$repo" show "HEAD:$compressed_manifest" > "$destination/$compressed_manifest"
git -C "$repo" show "HEAD:$binary_manifest" > "$destination/$binary_manifest"

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
done < "$destination/$chunk_manifest"

while read -r _ part; do
  cat "$destination/$(basename "$part")"
done < "$destination/$chunk_manifest" > "$compressed"

cd "$destination"
sha256sum -c "$compressed_manifest"
gzip -dc "$compressed" > "$node"
expected=$(awk '{print $1}' "$binary_manifest")
printf '%s  %s\n' "$expected" "$node" | sha256sum -c -
chmod 755 "$node"
"$node" --version
# JIT is enabled. These checks exercise the paths that needed the 750CL
# instruction substitutes: Math.sqrt, rounding, and the native Buffer
# converters (which no longer need the lib/buffer.js fallback).
"$node" -e 'const assert=require("node:assert");
const b=Buffer.from("abc");
assert.strictEqual(b.toString("hex"),"616263");
assert.strictEqual(b.toString("base64"),"YWJj");
assert.strictEqual(Math.sqrt(2),1.4142135623730951);
assert.strictEqual(Math.round(-2.5),-2);
assert.strictEqual(Math.floor(-2.5),-3);
const s=new BigInt64Array(new SharedArrayBuffer(8));
Atomics.store(s,0,123n);
assert.strictEqual(Atomics.load(s,0),123n);
console.log(process.version,process.arch,process.platform);'
