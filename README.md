# Node.js for Wii Linux PPC32

Prebuilt Node.js 22.11.0 for Wii Linux PPC32 big-endian.

This project distributes a standalone `node` executable. It does not require
building Node.js on the Wii.

## Unreliable Network Install

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

## Install

Download the release asset, verify it, then run it from a new path. Do not
replace the system Node.js installation.

```sh
sha256sum node22-ppc32-20260717
chmod 755 node22-ppc32-20260717
./node22-ppc32-20260717 --version
./node22-ppc32-20260717 -e 'console.log(process.version, process.arch, process.platform)'
```

## Verification

The published binary was built as an ELF32 PowerPC big-endian executable and
passed QEMU PPC user-mode checks for Node.js startup, `node:assert`, BigInt,
regular expressions, TypedArray, JSON, TextEncoder/Decoder, and built-in
modules. Hardware validation on Wii Linux remains a separate release check.

## License

Node.js is distributed under the MIT License. See [LICENSE](LICENSE).
