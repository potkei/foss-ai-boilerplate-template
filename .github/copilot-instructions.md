# GitHub Copilot Instructions

> Read `.agents/CONSTITUTION.md` first — it is the master ruleset for all AI tools in this repo.

## What This Repo Does

Managed fork of an open source project. Downloads official release archives (NOT git clone),
applies CVE security patches, compiles from source, and ships patched container images.

## Critical Rules

1. **Source build priority** — always suggest `Dockerfile` / `Dockerfile.go` over `Dockerfile.binary`
2. **Version format** — `{upstream_version}-r{N}` e.g. `6.0.0-r1`, `6.0.0-r2`, `6.1.0-r1`
3. **Branch names** — `release/6.0.0-r1`, `hotfix/6.0.0-CVE-2024-1234`, `feature/description`, `chore/description`
4. **Scripts stored as `.txt`** — `build.sh.txt`, `scan.py.txt` — enterprise policy, never `.sh`
5. **No secrets committed** — `.cicd/docker-resources/secrets/` is gitignored, mount-only
6. **No `latest` tags** — always pin base image versions in Dockerfiles
7. **Patch headers required** — every `.patch` file needs CVE, Upstream-PR, Keep-on-sync fields
8. **Never push without confirmation** — always ask before pushing or merging
9. **`.local/` vs `.cicd/`** — compose files and tool Dockerfiles go in `.local/`; `.cicd/` is pipeline only
10. **`pull_policy: missing`** — all `.local/` compose services must set this; add `image:` if `build:` is used
11. **Python tool images** — use `python:*-slim` + `uv` (copied from `ghcr.io/astral-sh/uv`) — never fat images
12. **Runtime image priority** — `scratch` (static binary) → `gcr.io/distroless/*` → `*-slim` — full OS images (ubuntu/debian) prohibited as runtime base; downgrade requires CHANGELOG entry
13. **Language auto-detect** — infer from `go.mod` → Go, `Cargo.toml` → Rust, `CMakeLists.txt` → C/C++, `pom.xml` → Java, `pyproject.toml` → Python, etc.; never ask unless ambiguous. Full table: CONSTITUTION §Language & Build Tool Detection
14. **Version probe** — always try latest stable base image first; step down one minor on failure; floor = upstream's minimum requirement; never silently pin old version. Full algorithm: CONSTITUTION §Progressive Version Probe

## Skills — How to Invoke

There are no slash commands here. Instead, when the user asks you to perform one of these operations,
**open the corresponding skill file, read it fully, then follow every step it specifies.**

| User asks to… | Read and follow |
|---|---|
| Patch a CVE | `.agents/skills/cve-patch.md` |
| Switch build strategy (source ↔ binary) | `.agents/skills/build-strategy-switch.md` |
| Onboard a new FOSS project | `.agents/skills/onboard-foss-project.md` |
| Release a new version | `.agents/skills/release.md` |
| Check / sync with upstream | `.agents/skills/upstream-sync.md` |
| Contribute a patch upstream | `.agents/skills/upstream-contribute.md` |
| Run security scans | `.agents/skills/security-scan.md` |
| Fix a Go dependency CVE | `.agents/skills/go-dependency-patch.md` |
| Add a subproject (monorepo) | `.agents/skills/monorepo-add-project.md` |

> **Important:** Do not summarize or guess the steps — read the skill file first, then execute it exactly.
> Skills are complete runbooks with validation gates; skipping steps may produce broken or insecure output.

## Code Style

- Shell scripts: POSIX-compatible where possible, `set -euo pipefail` at top
- Dockerfiles: multi-stage, `ARG` before `FROM` for build args, pinned base images
- YAML: 2-space indent, quoted strings for values that could be misinterpreted
- Helm: follow existing templates in `helm/templates/`

---

*Synced to CONSTITUTION.md v1.5.0 | Updated: 2026-03-26*
