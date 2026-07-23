# Node.js for Wii Linux PPC32

Prebuilt Node.js 22.11.0 for Wii Linux PPC32 big-endian.

This project distributes a standalone `node` executable. It does not require
building Node.js on the Wii.

## Current Build: `jitless-r2`

`node-v22.11.0-wii-ppc32-jitless-r2` is the current build. It is a PPC32
big-endian Node.js 22.11.0 executable that must be run with V8 JIT disabled.
It includes a JavaScript fallback for Buffer string conversions, which fixes
the PPC32 failures observed in `Buffer#toString()` and npm.

The binary SHA-256 is recorded in
`SHA256SUMS.node-v22.11.0-wii-ppc32-jitless-r2`. The source-level Buffer
change is available as
`patches/0001-ppc32-buffer-fallback.patch` for review.

This repository distributes a tested binary and its targeted Buffer patch. It
does not currently claim a fully reproducible upstream Node.js cross-build.

## Current Build Install on an Unreliable Network

The `chunks` branch contains the gzip-compressed `jitless-r2` executable split
into 1 MB chunks. Clone metadata only, retrieve the installer, then let it
fetch and verify each chunk separately:

```sh
git clone --depth 1 --filter=blob:none --no-checkout --branch chunks https://github.com/tanpang-dev/node-wii-ppc32.git node22-chunks
cd node22-chunks
git show HEAD:install-bufferfix-from-chunks.sh > install-bufferfix-from-chunks.sh
chmod 755 install-bufferfix-from-chunks.sh
./install-bufferfix-from-chunks.sh /root/node22-jitless-r2
```

The installer does not replace the system Node.js installation.

## Legacy Build Install on an Unreliable Network

The `chunks` branch contains a gzip-compressed executable split into 1 MB
chunks. It is intended for Wii systems where one large Git transfer resets.
Clone metadata only, retrieve the installer, then let it fetch and verify each
chunk separately:

```sh
git clone --depth 1 --filter=blob:none --no-checkout --branch chunks https://github.com/tanpang-dev/node-wii-ppc32.git node22-chunks
cd node22-chunks
git show HEAD:install-from-chunks.sh > install-from-chunks.sh
chmod 755 install-from-chunks.sh
./install-from-chunks.sh /root/node22-github-chunks
```

The installer retries each missing chunk, verifies every chunk, verifies the
combined gzip file and final executable, then runs a basic Node.js test. It
does not replace the system Node.js installation.

## Legacy Build Install

Download the release asset, verify it, then run it from a new path. Do not
replace the system Node.js installation.

```sh
sha256sum node22-ppc32-20260717
chmod 755 node22-ppc32-20260717
./node22-ppc32-20260717 --version
./node22-ppc32-20260717 -e 'console.log(process.version, process.arch, process.platform)'
```

## Verification

The `jitless-r2` build was validated on Wii Linux with Node.js startup,
Buffer hex/base64/UTF-8 conversion, npm 6.14.12, a real `npm install`, HTTP,
and a LINE webhook signature check. It is an ELF32 PowerPC big-endian
executable. Hardware behavior outside that environment remains a separate
compatibility concern.

Run the current build explicitly with `--jitless`:

```sh
./node-v22.11.0-wii-ppc32-jitless-r2 --jitless --version
```

## License

Node.js is distributed under the MIT License. See [LICENSE](LICENSE).
