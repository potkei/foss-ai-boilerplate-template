# Getting Started

## Prerequisites

- Docker (with Compose v2)
- Git
- jq
- Optional: cosign (image signing), helm (Kubernetes deployments)

## Setup

```bash
# Clone the repo
git clone <repo-url> && cd <repo-name>

# First-run setup — translates scripts, creates directories
./init.sh

# Onboard your FOSS project (interactive wizard)
make onboard
```

## Daily Workflow

```bash
# Build from source
make build

# Run security scans
make scan

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
