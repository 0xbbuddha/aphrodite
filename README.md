<p align="center">
  <img alt="Aphrodite Logo" src="Payload_Type/aphrodite/agent_functions/aphrodite.svg" height="30%" width="30%">
</p>

# Aphrodite

Aphrodite is a lightweight cross-platform agent written in Nim, designed for Mythic 3.0 and newer. Named after Aphrodite, goddess of beauty — compiled to a native binary, no runtime dependencies required.

## Features

- Linux and Windows support (cross-compiled from Linux via mingw-w64)
- HTTP C2 profile
- AES-256-CBC + HMAC-SHA256 encryption (PSK mode)
- Plaintext mode (no encryption, for testing)
- Configurable sleep interval and jitter
- Kill date support
- Static binary option (no shared library dependencies on target)
- 8 built-in commands covering:
  - Reconnaissance (`whoami`, `ps` via shell)
  - File operations (`ls`, `cat`, `cd`, `pwd`)
  - Execution (`shell`)
  - Agent control (`sleep`, `exit`)

## Installation

1.) Install Mythic from [here](https://github.com/its-a-feature/Mythic)

2.) From the Mythic install directory, run the following command:

```bash
./mythic-cli install github https://github.com/0xbbuddha/aphrodite
```

## Supported C2 Profiles

### HTTP

Aphrodite communicates over the default HTTP profile used by Mythic. All taskings and responses are done via POST requests.

> **Note:** Only PSK mode is supported. Disable "Encrypted Key Exchange" in the HTTP profile settings, or leave AESPSK as `none` for plaintext mode.

## Build Options

| Option          | Type    | Default   | Description                                              |
|-----------------|---------|-----------|----------------------------------------------------------|
| `target_os`     | Choice  | `linux`   | Target OS: `linux` or `windows`                          |
| `architecture`  | Choice  | `amd64`   | Target architecture (amd64 only)                         |
| `debug`         | Boolean | `false`   | Enable verbose debug output (larger binary)              |
| `static_binary` | Boolean | `false`   | Statically link binary (no shared library dependencies)  |

## Opsec Considerations

### Native Binary

Aphrodite compiles to a native binary with no runtime interpreter required on the target. This reduces the detection surface compared to script-based agents.

### Encryption

| Mode       | Description                                                           |
|------------|-----------------------------------------------------------------------|
| PSK        | AES-256-CBC + HMAC-SHA256 with a pre-shared key baked into the binary |
| Plaintext  | No encryption — for lab/testing use only                              |

> EKE (Encrypted Key Exchange) is not yet supported.

### Sleep Interval

Tune the sleep interval and jitter according to your operational requirements. Higher sleep values reduce network noise at the cost of task responsiveness.

## Known Issues

### No EKE Support

Aphrodite does not support Encrypted Key Exchange (RSA staging). Only PSK mode and plaintext mode are available.

### Windows Cross-Compilation

Windows binaries are cross-compiled from Linux using mingw-w64. Some edge cases around Windows API behavior may differ from a natively compiled binary.

## Credit

- [@0xbbuddha](https://github.com/0xbbuddha) — Author
