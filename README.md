# Haider Ali OpenCode System

A professional, automated, idempotent Bash installer for running **OpenCode AI**
on Android via **Termux → Ubuntu → Node.js → OpenCode AI**.

The user runs a single command. The system detects, installs, verifies,
diagnoses, recovers and launches — without the user typing the underlying
installation commands one by one.

| | |
|---|---|
| **Project owner** | Haider Ali |
| **Version** | 1.0.0 |
| **Platform** | Termux on Android (arm64 / arm / x86_64) |

---

## Purpose

Building OpenCode AI on Android by hand requires eleven error-prone commands
run in two different environments (Termux and an Ubuntu proot container). This
system wraps those eleven original commands behind a professional
orchestration layer that:

1. Detects the Termux environment, network and Android shared storage.
2. Installs/checks `proot-distro` and Ubuntu.
3. Enters Ubuntu with `/storage/emulated/0` bound to `/mobile_storage`.
4. Updates Ubuntu, installs `curl`, Node.js 20 and OpenCode AI.
5. Verifies everything, then launches OpenCode.

It is safe to run repeatedly. Healthy components are skipped, missing
components are installed, broken components are diagnosed with safe recovery,
and unsafe situations stop with a clear explanation.

## Architecture

```
Haider-Ali-OpenCode/
├── install.sh                 # orchestrator (entry point)
├── config.sh                  # central configuration
├── README.md
├── commands/                  # the 11 wrapped stages
│   ├── 01-termux-update.sh    #   pkg update && pkg upgrade -y
│   ├── 02-proot.sh            #   pkg install proot-distro -y
│   ├── 03-storage.sh          #   termux-setup-storage
│   ├── 04-ubuntu.sh           #   proot-distro install ubuntu
│   ├── 05-ubuntu-login.sh     #   proot-distro login ubuntu --bind ...
│   ├── 06-ubuntu-update.sh    #   apt update && apt upgrade -y
│   ├── 07-curl.sh             #   apt install curl -y
│   ├── 08-node-repository.sh  #   NodeSource setup_20.x
│   ├── 09-nodejs.sh           #   apt install -y nodejs
│   ├── 10-opencode.sh         #   npm i -g opencode-ai
│   └── 11-launch.sh           #   opencode
├── lib/
│   ├── ui.sh                  # branding, colours, stage display
│   ├── logger.sh              # per-run log files
│   ├── runner.sh              # command execution engine
│   ├── checker.sh             # detection & state checks
│   ├── recovery.sh            # safe recovery engine
│   ├── system.sh              # Termux engines (stages 01–03)
│   ├── ubuntu.sh              # Ubuntu engines (stages 04–06)
│   └── opencode.sh            # Node.js/OpenCode engines (stages 07–11)
└── tests/
    ├── harness.sh
    ├── test-ui.sh
    ├── test-system.sh
    ├── test-recovery.sh
    ├── test-opencode.sh
    └── run-tests.sh
```

**Design rule.** The original Termux / Ubuntu / apt / npm / Node.js /
proot-distro / OpenCode commands are never modified or replaced. They remain
the underlying engines. This project only controls *when* they run, how output
is displayed and logged, how failures are classified, and how safe recovery is
attempted.

## Requirements

- A Termux installation on Android (from [F-Droid](https://f-droid.org) or the
  Play Store).
- Enough free storage for Termux + Ubuntu (several GB).
- An internet connection.
- No root is required (proot is used).

## Installation

### One-command installation

```bash
git clone <repository-url> &&
cd Haider-Ali-OpenCode &&
chmod +x install.sh &&
./install.sh
```

The user never runs the eleven underlying commands manually. On first run
everything is installed; on later runs the system verifies, skips healthy
components, and repairs where safe.

### Manual installation (for review)

Each stage can be executed on its own, e.g.:

```bash
bash commands/04-ubuntu.sh
```

### Environment-only report

```bash
./install.sh --check
```

Other options: `--help`, `--version`, `--no-color`, `--no-log`.

## How the stages work

| # | Stage | Original command | Behaviour |
|---|-------|------------------|-----------|
| 01 | Termux Package Engine | `pkg update && pkg upgrade -y` | checks `pkg` + network, then updates/upgrades |
| 02 | proot-distro | `pkg install proot-distro -y` | skips if already installed; verifies `--version` |
| 03 | Android Storage Access | `termux-setup-storage` | skipped when `/storage/emulated/0` is already readable |
| 04 | Ubuntu Container | `proot-distro install ubuntu` | **never run blindly** — Ubuntu state is detected first (see below) |
| 05 | Ubuntu Login / Bind | `proot-distro login ubuntu --bind /storage/emulated/0:/mobile_storage` | non-interactive; verifies `/mobile_storage` exists inside Ubuntu |
| 06 | Ubuntu Package Engine | `apt update && apt upgrade -y` | non-interactive (`DEBIAN_FRONTEND=noninteractive`) |
| 07 | curl | `apt install curl -y` | skipped when already installed |
| 08 | Node.js Repository | `curl -fsSL https://deb.nodesource.com/setup_20.x \| bash -` | downloaded over HTTPS, validated, then executed |
| 09 | Node.js Runtime | `apt install -y nodejs` | skips an already-correct major version; verifies `node`/`npm` |
| 10 | OpenCode AI | `npm i -g opencode-ai` | verifies existing installs; verifies `opencode --version` |
| 11 | Launch OpenCode | `opencode` | final verification then launches; refuses on failure |

### Ubuntu state detection

`proot-distro install ubuntu` is **never** executed blindly. `ubuntu_detect_state`
reports one of:

- `NOT_INSTALLED` → install
- `HEALTHY` → skip
- `BUSY` → do not install; wait and re-check (the `container 'ubuntu' is busy`
  condition is treated as a state, not a generic error)
- `BROKEN` → safe health re-check only; no destructive action
- `UNKNOWN` → stop and explain

No component is considered healthy just because a binary exists — each one is
probed (`node --version`, `npm --version`, `opencode --version`, a login probe
inside Ubuntu, etc.).

## Recovery behaviour

The recovery engine (`lib/recovery.sh`) never blindly repeats a failing
command. It:

1. Captures the error.
2. Classifies it (`network`, `package`, `ubuntu_busy`, `ubuntu_broken`,
   `missing_command`, `permission`, `unknown`).
3. Applies a **safe** action (check connectivity, `apt-get -f install`,
   wait for a busy container, refresh indexes, re-check permissions).
4. Retries up to `MAX_RECOVERY_ATTEMPTS` (3).
5. Stops with a diagnostic summary when no safe recovery exists.

**Never done automatically:** deleting Ubuntu, deleting user files, wiping
package databases, or forcing destructive repairs.

## Security

- No GitHub tokens, passwords, API keys, SSH keys or OpenCode credentials are
  ever hard-coded, printed or committed.
- Credentials belong in environment variables or secure credential storage.
- Logs are written to `~/.haider-ali-opencode/logs/` and contain no secrets.
- The NodeSource script is downloaded over HTTPS and validated before
  execution. It is the vendor's own installer — review it at
  `/tmp/nodesource_setup.sh` inside Ubuntu if you wish. Nothing is claimed to
  be "100% safe".

## Configuration

All settings live in `config.sh`:

| Variable | Default | Meaning |
|---|---|---|
| `APP_NAME` / `APP_VERSION` | Haider Ali OpenCode System / 1.0.0 | branding |
| `UBUNTU_NAME` | `ubuntu` | proot-distro container name |
| `UBUNTU_STORAGE_BIND` | `/storage/emulated/0:/mobile_storage` | storage bind |
| `NODE_MAJOR_VERSION` | `20` | required Node.js major |
| `OPENCODE_PACKAGE` | `opencode-ai` | npm package name |
| `MAX_RECOVERY_ATTEMPTS` | `3` | retry cap |
| `RECOVERY_RETRY_DELAY` | `2` | seconds between retries |
| `AUTO_RECOVERY` | `true` | enable safe recovery |
| `ENABLE_COLORS` / `ENABLE_LOGGING` | `true` | UI/logging switches |
| `LOG_DIRECTORY` | `~/.haider-ali-opencode/logs` | log destination |

## Troubleshooting

- **"environment is not Termux"** — run inside Termux on Android.
- **Storage not granted** — stage 03 requests it; accept the Android prompt.
  Grant *Files and media* permissions if the prompt is skipped.
- **`container 'ubuntu' is busy`** — a previous Ubuntu session is running.
  Close it (or wait), then re-run; the installer detects this state and will
  not attempt a duplicate install.
- **Network errors** — the installer verifies connectivity before each network
  stage and retries only when connectivity is restored.
- **Logs** — each run writes a log under `~/.haider-ali-opencode/logs/` with
  stage progress, commands, exit codes and recovery attempts.

## Uninstall

Remove the cloned directory. Optionally remove the proot Ubuntu container:

```bash
proot-distro remove ubuntu
```

and the log directory:

```bash
rm -rf ~/.haider-ali-opencode
```

Termux itself and other packages are left untouched.

## Development / testing

```bash
bash tests/run-tests.sh
```

This runs `bash -n` on every `.sh` file, `shellcheck` when available, and the
four test suites (UI, system detection, recovery, OpenCode detection).

Test results are reported honestly — a suite only reports `PASS` when it was
actually run and every assertion succeeded.

## Supported environment

- Termux on Android; proot-distro and Ubuntu inside it; Ubuntu 20.04+ images.
- Bash 4+ (Termux ships Bash 5).
- Tested logic is environment-agnostic; detection tests adapt to the machine
  they run on (Termux vs. non-Termux).

## Version

**1.0.0** — initial release.
