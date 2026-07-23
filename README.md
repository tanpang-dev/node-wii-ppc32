# Node.js for Wii Linux PPC32

Prebuilt Node.js 22.11.0 for Wii Linux PPC32 big-endian.

This project distributes a standalone `node` executable. It does not require
building Node.js on the Wii.

## Current Build

The current build is `node-v22.11.0-wii-ppc32-jitless-r2`. It includes a
PPC32 Buffer string-conversion fallback that fixes `Buffer#toString()` and
npm failures observed on Wii Linux. Its SHA-256 is recorded in
`SHA256SUMS.node-v22.11.0-wii-ppc32-jitless-r2`.

The binary is distributed in 1 MB verified chunks on the
[`chunks` branch](https://github.com/tanpang-dev/node-wii-ppc32/tree/chunks).
That branch also contains the dedicated installer and the source-level Buffer
patch at `patches/0001-ppc32-buffer-fallback.patch`.

The current build must be run with V8 JIT disabled:

```sh
./node-v22.11.0-wii-ppc32-jitless-r2 --jitless --version
```

## Legacy Build

The original release asset remains available for compatibility testing. Do not
replace the system Node.js installation.

```sh
sha256sum node22-ppc32-20260717
chmod 755 node22-ppc32-20260717
./node22-ppc32-20260717 --version
./node22-ppc32-20260717 -e 'console.log(process.version, process.arch, process.platform)'
```

## Verification

The current build was validated on Wii Linux with Node.js startup, Buffer
hex/base64/UTF-8 conversion, npm 6.14.12, a real `npm install`, HTTP, and a
LINE webhook signature check. It is an ELF32 PowerPC big-endian executable.
Hardware behavior outside that environment remains a separate compatibility
concern.

## License

Node.js is distributed under the MIT License. See [LICENSE](LICENSE).
