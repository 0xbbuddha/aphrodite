<p align="center">
  <img alt="Aphrodite Logo" src="Payload_Type/aphrodite/agent_functions/aphrodite.svg" height="30%" width="30%">
</p>

# Aphrodite

Aphrodite is a lightweight cross-platform agent written in Nim, designed for Mythic 3.0 and newer. Named after Aphrodite, goddess of beauty — compiled to a native binary, no runtime dependencies required.

## Features

- Linux and Windows support (cross-compiled from Linux via mingw-w64)
- HTTP and TCP C2 profiles
- AES-256-CBC + HMAC-SHA256 encryption (PSK mode)
- EKE mode — RSA-4096 key exchange, session AES key negotiated at runtime (Linux)
- Plaintext mode (no encryption, for testing)
- Configurable sleep interval and jitter
- Kill date support
- Static binary option (no shared library dependencies on target)
- SOCKS5 proxy support (tunneling through the agent)
- 37 built-in commands covering:
  - Reconnaissance (`whoami`, `ps`, `hostname`, `ifconfig`, `arp`, `nslookup`, `uptime`, `netstat`)
  - File operations (`ls`, `cat`, `cd`, `pwd`, `mkdir`, `rm`, `mv`, `cp`, `tail`, `drives`, `chmod`, `chown`, `find`, `write`)
  - File transfer (`download`, `upload`)
  - Execution (`shell`, `psh`)
  - Environment (`getenv`, `setenv`, `env`)
  - Agent control (`sleep`, `exit`, `kill`, `echo`, `socks`, `jobs`, `jobkill`, `config`)

## Installation

1.) Install Mythic from [here](https://github.com/its-a-feature/Mythic)

2.) From the Mythic install directory, run the following command:

```bash
./mythic-cli install github https://github.com/0xbbuddha/aphrodite
```

## Supported C2 Profiles

### HTTP

Aphrodite communicates over the default HTTP profile used by Mythic. All taskings and responses are done via POST requests.

Encryption modes:
- **PSK** — pre-shared AES-256 key baked at build time (disable "Encrypted Key Exchange")
- **EKE** — RSA-4096 staging: agent generates a key pair at startup, Mythic encrypts the session AES key with the public key (Linux only)
- **Plaintext** — no encryption, for testing

### TCP

Direct TCP connection to the Mythic server. Messages are framed with a 4-byte big-endian length prefix. Requires the [Mythic TCP C2 profile](https://github.com/MythicC2Profiles/tcp) installed on the server:

```bash
./mythic-cli install github https://github.com/MythicC2Profiles/tcp
```

Same encryption modes as HTTP.

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
| EKE        | RSA-4096 staging — session AES key negotiated at runtime (Linux)      |
| Plaintext  | No encryption — for lab/testing use only                              |

### Sleep Interval

Tune the sleep interval and jitter according to your operational requirements. Higher sleep values reduce network noise at the cost of task responsiveness.

## Known Issues

### EKE — Linux Only

EKE (RSA-4096 staging) requires OpenSSL at build time and is currently only supported for Linux targets. Windows builds fall back to PSK mode automatically.

### Windows Cross-Compilation

Windows binaries are cross-compiled from Linux using mingw-w64. Some edge cases around Windows API behavior may differ from a natively compiled binary.

## Credit

- [@0xbbuddha](https://github.com/0xbbuddha) — Author
