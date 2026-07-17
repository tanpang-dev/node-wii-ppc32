# Node.js for Wii Linux PPC32

Prebuilt Node.js 22.11.0 for Wii Linux PPC32 big-endian.

This project distributes a standalone `node` executable. It does not require
building Node.js on the Wii.

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
