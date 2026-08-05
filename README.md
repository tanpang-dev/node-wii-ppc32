# Node.js for Wii Linux PPC32

Prebuilt Node.js 22.11.0 for Wii Linux PPC32 big-endian.

This project distributes a standalone `node` executable. It does not require
building Node.js on the Wii.

## Current Build: `jit-r1`

`node-v22.11.0-wii-ppc32-jit-r1` runs with **V8 JIT enabled**. Earlier builds
had to be started with `--jitless`; this one does not.

The 750CL (Broadway) CPU is missing instructions that V8's PPC backend assumes,
and V8 removed its PPC 32-bit code paths in 2024. This build restores those
code paths and substitutes the missing instructions in the code generator,
rather than working around the symptoms in JavaScript. As a result:

- `Math.sqrt` and the rounding functions work. The previous `jitless-r2` build
  crashes with SIGILL on `Math.sqrt`.
- The native `Buffer` string converters work, so the `lib/buffer.js` fallback
  that `jitless-r2` needed is gone.
- Compute-bound JavaScript is several times faster (see Measurements).

The binary SHA-256 is recorded in `SHA256SUMS.node-v22.11.0-wii-ppc32-jit-r1`.
The source changes are in `patches/` for review.

This repository distributes a tested binary and the patches used to produce it.
It does not claim a fully reproducible upstream Node.js cross-build.

## Install on an Unreliable Network

The `chunks` branch contains the gzip-compressed executable split into 1 MB
chunks. Clone metadata only, retrieve the installer, then let it fetch and
verify each chunk separately:

```sh
git clone --depth 1 --filter=blob:none --no-checkout --branch chunks https://github.com/tanpang-dev/node-wii-ppc32.git node22-chunks
cd node22-chunks
git show HEAD:install-jit-from-chunks.sh > install-jit-from-chunks.sh
chmod 755 install-jit-from-chunks.sh
./install-jit-from-chunks.sh /root/node22-jit-r1
```

The installer retries each missing chunk, verifies every chunk, verifies the
combined gzip file and the final executable, then runs a self-test. It does not
replace the system Node.js installation.

## Verification

`jit-r1` was validated on Wii Linux (PowerPC 750CL, 729 MHz, 73 MB RAM):

- Node.js startup, `npm 6.14.12`
- `Buffer` hex/base64/UTF-8 conversion, including multi-byte and 100 KB buffers
- `Math.sqrt`, `floor`/`ceil`/`round`/`trunc`, int/float conversion
- BigInt arithmetic, `Atomics` on `BigInt64Array`, `DataView` endianness
- `crypto`: SHA-256, HMAC, `randomBytes`, EC key generation, sign/verify
- HTTPS against a live API, running as a long-lived service
- TurboFan optimization of hot loops, `switch` jump tables, and regular
  expressions

The generated builtin code was checked with `objdump`: 654,056 instructions
contain none that the 750CL lacks.

It is an ELF32 PowerPC big-endian executable. Hardware behavior outside this
environment remains a separate compatibility concern.

## Measurements

Steady-state, same machine, `jit-r1` versus `jitless-r2`:

| Benchmark | jit-r1 | jitless-r2 |
|---|---|---|
| Arithmetic loop, 3,000,000 iterations | 221 ms | 2739 ms |
| Regular expression, 50,000 matches | 245 ms | 684 ms |
| Integer array sort, 50,000 elements | 336 ms | 490 ms |
| JSON round trip, 2,000 objects | 115 ms | 108 ms |
| `Math.sqrt` | works | SIGILL |

Resident memory is comparable (35 MB versus 33 MB). Startup is slower with JIT
enabled, roughly 2-4 seconds against roughly 2 seconds.

## Patches

| Patch | Contents |
|---|---|
| `0001-v8-ppc32-restore.patch` | Restores V8's PPC 32-bit code paths (shifts, multiply/divide, zero extension, memory operations, C linkage ABI, SIMD guards) and substitutes the instructions the 750CL lacks: `fsqrt`, `fcfid`/`fctidz`, `fri[mpzn]`, `popcnt`. Also adds `Int32Pair` and `Word32AtomicPair` instruction selection. |
| `0002-v8-ppc32-sysv-abi.patch` | Restores the PPC32 Linux SysV stack linkage constants. Without this, `JSEntry` saves the link register into the wrong slot of its caller's frame and JavaScript execution crashes immediately. |
| `0003-v8-simulator-32bit-host.patch` | Lets the PPC simulator compile on a 32-bit host, which is required because V8 builds its host tools with `-m32` when the target is PPC32. |
| `0004-v8-snapshot-header-endianness.patch` | The startup snapshot header is little-endian while its payload is target-endian. Makes the header accessors explicitly little-endian so they do not follow the target byte order. |
| `0005-build-cross-and-openssl-ppc.patch` | Cross-build configuration, and the missing OpenSSL `linux-ppc` branch. Without it, the arch selection falls back to `linux-x86_64` and bakes `-DL_ENDIAN` into a big-endian target. |

## Previous Build: `jitless-r2`

`node-v22.11.0-wii-ppc32-jitless-r2` remains available for comparison. It must
be run with `--jitless`, and it crashes on `Math.sqrt`. Its installer is
`install-bufferfix-from-chunks.sh` and its Buffer patch is
`patches/0001-ppc32-buffer-fallback.patch`.

## Legacy Build

The original release asset `node22-ppc32-20260717` remains available for
compatibility testing. Do not replace the system Node.js installation.

```sh
sha256sum node22-ppc32-20260717
chmod 755 node22-ppc32-20260717
./node22-ppc32-20260717 --version
```

## License

Node.js is distributed under the MIT License. See [LICENSE](LICENSE).
