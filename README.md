# Node.js for Wii Linux PPC32

Prebuilt Node.js 22.11.0 for Wii Linux PPC32 big-endian.

This project distributes a standalone `node` executable. It does not require
building Node.js on the Wii.

## Current Build: `jit-r2`

`node-v22.11.0-wii-ppc32-jit-r2` runs with **V8 JIT enabled**, including the
Sparkplug baseline tier. Earlier builds had to be started with `--jitless`;
this one does not.

The 750CL (Broadway) CPU is missing instructions that V8's PPC backend assumes,
and V8 removed its PPC 32-bit code paths in 2024. This build restores those
code paths and substitutes the missing instructions in the code generator,
rather than working around the symptoms in JavaScript. As a result:

- `Math.sqrt` and the rounding functions work. The previous `jitless-r2` build
  crashes with SIGILL on `Math.sqrt`.
- The native `Buffer` string converters work, so the `lib/buffer.js` fallback
  that `jitless-r2` needed is gone.
- Compute-bound JavaScript is several times faster (see Measurements).

The binary SHA-256 is recorded in `SHA256SUMS.node-v22.11.0-wii-ppc32-jit-r2`.
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
git show HEAD:install-jit-from-chunks-r2.sh > install-jit-from-chunks-r2.sh
chmod 755 install-jit-from-chunks-r2.sh
./install-jit-from-chunks-r2.sh /root/node22-jit-r2
```

The installer retries each missing chunk, verifies every chunk, verifies the
combined gzip file and the final executable, then runs a self-test. It does not
replace the system Node.js installation.

## Verification

`jit-r2` was validated on Wii Linux (PowerPC 750CL, 729 MHz, 73 MB RAM):

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

Steady-state, same machine, `jit-r2` versus `jitless-r2`:

| Benchmark | jit-r2 | jitless-r2 |
|---|---|---|
| Arithmetic loop, 3,000,000 iterations | 221 ms | 2739 ms |
| Regular expression, 50,000 matches | 245 ms | 684 ms |
| Integer array sort, 50,000 elements | 336 ms | 490 ms |
| JSON round trip, 2,000 objects | 115 ms | 108 ms |
| `Math.sqrt` | works | SIGILL |

Resident memory is comparable (35 MB versus 33 MB). Startup is slower with JIT
enabled, roughly 2-4 seconds against roughly 2 seconds.

## Sparkplug

`jit-r2` adds the Sparkplug baseline compiler, which `jit-r1` did not have.

V8 only dispatches its PPC baseline assembler for `V8_TARGET_ARCH_PPC64`, so
PPC32 fell through to `#error Unsupported target architecture`. That looks like
a missing port, but it is not: `baseline-assembler-ppc-inl.h` is written in
terms of pointer-width operations, and its eleven explicit 64-bit uses already
lower to `lwz`/`stw` on PPC32. Adding PPC32 to the two dispatch conditions is
the entire change.

Baseline code is about **1.8x faster than the interpreter** here, measured with
`--no-opt` at both 1,000 and 10,000 calls per function. In practice the
difference does not show, because hot code reaches TurboFan either way:

| | jit-r2 | `--no-sparkplug` |
|---|---|---|
| Steady state, request-shaped workload | 236 ms | 232 ms |
| First phase, including compilation | 1540 ms | 925 ms |

Sparkplug compiles on the main thread, and at 729 MHz that costs a few
milliseconds per function. Short-lived processes lose; long-lived ones break
even. It is enabled because it makes the tier structure correct, not because it
is faster.

## Patches

| Patch | Contents |
|---|---|
| `0001-v8-ppc32-restore.patch` | Restores V8's PPC 32-bit code paths (shifts, multiply/divide, zero extension, memory operations, C linkage ABI, SIMD guards) and substitutes the instructions the 750CL lacks: `fsqrt`, `fcfid`/`fctidz`, `fri[mpzn]`, `popcnt`. Also adds `Int32Pair` and `Word32AtomicPair` instruction selection. |
| `0002-v8-ppc32-sysv-abi.patch` | Restores the PPC32 Linux SysV stack linkage constants. Without this, `JSEntry` saves the link register into the wrong slot of its caller's frame and JavaScript execution crashes immediately. |
| `0003-v8-simulator-32bit-host.patch` | Lets the PPC simulator compile on a 32-bit host, which is required because V8 builds its host tools with `-m32` when the target is PPC32. |
| `0004-v8-snapshot-header-endianness.patch` | The startup snapshot header is little-endian while its payload is target-endian. Makes the header accessors explicitly little-endian so they do not follow the target byte order. |
| `0006-v8-enable-sparkplug-ppc32.patch` | Adds PPC32 to the two Sparkplug dispatch conditions and enables the feature. Eleven lines, most of them comments. |
| `0005-build-cross-and-openssl-ppc.patch` | Cross-build configuration, and the missing OpenSSL `linux-ppc` branch. Without it, the arch selection falls back to `linux-x86_64` and bakes `-DL_ENDIAN` into a big-endian target. |

## WebAssembly

WebAssembly is disabled. Liftoff's PPC implementation assumes an i64 fits in one
register, but PPC32 sets `kNeedI64RegPair`, so every 64-bit operation needs a
register pair. The PPC file is 2979 lines against ia32's 4985, and that gap is
the work. `jump-table-assembler` has no PPC32 branch either.

SIMD is not the obstacle. `SupportsWasmSimd128()` already requires `PPC_9_PLUS`,
so the 750CL reports no SIMD support and modules that avoid it would still run.

## Previous Builds

`node-v22.11.0-wii-ppc32-jit-r1` is the same port without Sparkplug. Its
installer is `install-jit-from-chunks.sh`.

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
