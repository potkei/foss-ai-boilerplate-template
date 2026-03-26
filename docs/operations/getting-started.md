# Getting Started

## Prerequisites

- Docker or Podman (with Compose v2)
- Git
- Go (recommended — used to auto-build `jq` if not installed)
- Optional: `jq` (auto-built via Go during `init.sh` if missing), cosign (image signing), helm (Kubernetes deployments)

## Setup

```bash
# Clone the repo
git clone <repo-url> && cd <repo-name>

# Bootstrap: rename init.sh.txt to init.sh (required once)
mv init.sh.txt init.sh
chmod +x init.sh

# First-run setup — auto-builds jq if missing, translates scripts, creates directories
./init.sh

# Onboard your FOSS project (interactive wizard — run inside Claude Code)
/onboard-foss-project
```

`init.sh` will:
- Detect Docker or Podman automatically
- Build `jq` from `.tools/jsonq/` using Go if `jq` is not installed (uses your configured `GOPROXY`)
- Translate all `.sh.txt` source files to executable `.sh`
- Create required directories (`patches/`, `reports/`, `docs/`, `helm/`)

## Daily Workflow

```bash
# Build from source
./build.sh

# Run security scans
./build.sh --scan

# View scan reports
ls reports/

# Serve documentation
make docs
# → http://localhost:8000
```

## Project Configuration

After onboarding, your project config lives in `package.json`:

```json
{
  "name": "nginx-fork",
  "version": "1.27.3-r1",
  "upstream": {
    "name": "nginx",
    "version": "1.27.3",
    "archiveUrl": "https://nginx.org/download/nginx-1.27.3.tar.gz",
    "sha256": "abc123...",
    "language": "c"
  }
}
```
