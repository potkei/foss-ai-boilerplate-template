# AI Constitution — Shared (All AI Tools)

> This is the master constitution for all AI assistants operating in this repository.
> Claude Code → also read `CLAUDE.md` at repo root.
> GitHub Copilot → also read `.github/copilot-instructions.md`.
> Cursor → also read `.cursor/rules/main.mdc`.
> Windsurf → also read `.windsurfrules` at repo root.
> OpenAI Codex → also read `.codex/instructions.md`.

---

## What This Repository Is

A managed fork of an open source project. We download official release archives (tarball/zip),
apply our own CVE security patches, compile from source, and ship container images — faster
than upstream can release fixes.

**We do NOT git-clone upstream. We download official release archives only.**

---

## Non-Negotiable Rules (All AI Tools)

### 1. Build Priority
- Source build (`Dockerfile` / `Dockerfile.go`) is ALWAYS preferred
- Binary (`Dockerfile.binary`) is FALLBACK only — temporary, documented in CHANGELOG
- Never delete either Dockerfile

### 2. Versioning
- Format: `{upstream_version}-r{N}` — example: `6.0.0-r1`, `6.0.0-r2`, `6.1.0-r1`
- Revision resets to `r1` when upstream version changes
- Git tag = Docker tag = Helm appVersion = package.json version (all must match)

### 3. Branch Names
- `release/6.0.0-r1` — release branches match version exactly
- `hotfix/6.0.0-CVE-2024-1234` — CVE patch, version-prefixed for traceability
- `hotfix/6.0.0-fix-description` — non-CVE hotfix on a release line
- `feature/description` — features
- `chore/description` — maintenance
- No direct push to `main`

**Hotfix naming rule:** `hotfix/{upstream_version}-{CVE-ID}` — the version prefix makes it
immediately clear which release line the fix targets and allows easy grouping in git log.
Multiple CVEs: `hotfix/6.0.0-CVE-2024-1234-CVE-2024-5678`.

### 4. Script Files
- All shell/Python/batch scripts are stored with `.txt` extension: `build.sh.txt`, `scan.py.txt`
- This is intentional — enterprise security policy blocks executable extensions
- When onboarding or running for the first time, the `onboard-foss-project` skill
  translates them back to original extensions and sets executable permissions
- **Never rename `.txt` back to `.sh`/`.py`/`.bat` manually — use the skill**

### 5. Secrets
- Never commit secrets, credentials, tokens, or keys
- `.cicd/docker-resources/secrets/` is mount-only and fully gitignored
- If you see a secret in code, stop and alert the user

### 6. Patches
- All CVE patches live in `patches/` named: `0001-CVE-YYYY-NNNNN-description.patch`
- Each patch must have a header with: CVE ID, Upstream-PR, Upstream-Fix, Keep-on-sync
- Never skip checksum verification of upstream archives

### 7. Confirmations Required
- Never push to remote without explicit human confirmation
- Never merge PRs without explicit human confirmation
- Never activate binary fallback without tech lead approval

### 8. Local Dev Tooling
- All local compose files and tool Dockerfiles live in `.local/` — never in `.cicd/`
- `.cicd/` is for CI/CD pipeline config only (Jenkins, scan configs, scripts, secrets)
- Scanner version pins live in `.cicd/scan-versions.env` — shared between local and CI
- Scan exceptions live in `.cicd/scan-exceptions.yml` — audited, CI-enforced
- All `.local/` compose services must use `pull_policy: missing` to avoid rebuilds
- Build-based services must declare `image: foss-*:local` for local image caching

### 9. Python Tool Images
- Tool images built from Python (checkov, semgrep, mkdocs-material) use `python:*-slim` + `uv`
- `uv` binary copied from `ghcr.io/astral-sh/uv` — never installed via pip
- Version pinned via `ARG` in Dockerfile + build arg in compose

---

## Skill Directory

| Need | Skill File |
|---|---|
| Apply a CVE patch | `.agents/skills/cve-patch.md` |
| Switch source ↔ binary build | `.agents/skills/build-strategy-switch.md` |
| Onboard a new FOSS project | `.agents/skills/onboard-foss-project.md` |
| Release a new version | `.agents/skills/release.md` |
| Check upstream for new version | `.agents/skills/upstream-sync.md` |
| Contribute patch back to upstream | `.agents/skills/upstream-contribute.md` |
| Run security scans | `.agents/skills/security-scan.md` |
| Patch a Go dependency CVE | `.agents/skills/go-dependency-patch.md` |
| Add project to monorepo | `.agents/skills/monorepo-add-project.md` |

---

## Folder Map

```
.agents/skills/     Shared AI runbooks (all tools)
.claude/commands/   Claude Code slash commands
.github/            Copilot instructions, workflows, PR templates
.cursor/rules/      Cursor rules
.codex/             Codex instructions
.windsurfrules      Windsurf rules (root file)
.cicd/              CI/CD pipeline only — Jenkins, scan configs, scripts (.txt), secrets
  scan-versions.env     Scanner version pins (shared: local + CI)
  scan-exceptions.yml   Accepted CVE exceptions with expiry (CI-enforced)
  jenkins_config.yml    Jenkins pipeline definition
  docker-resources/     Scripts (.sh.txt) and secrets (mount-only, gitignored)
.local/             Local dev tooling — compose files + tool Dockerfiles (NOT CI/CD)
  docker-compose.build.yaml       Build product image locally
  docker-compose.run.yml          Run product image locally after build
  docker-compose.scan.yml         Full local scan stack (SonarQube + all scanners)
  docker-compose.scan.external.yml  Connect to external SonarQube
  docker-compose.registry.yml     Local Harbor registry
  docker-compose.docs.yml         Serve MkDocs documentation
  Dockerfile.docs                 MkDocs Material built via uv
  Dockerfile.checkov              Checkov built via uv
  Dockerfile.semgrep              Semgrep built via uv
docs/               MkDocs documentation content + config (mkdocs.yml stays at root)
helm/               Kubernetes Helm chart
patches/            CVE patch files (source build only)
projects/           Monorepo subprojects (if applicable)
reports/            Scan output — gitignored
Dockerfile          Product source build — C/generic (PRIORITY)
Dockerfile.go       Product source build — Go-specific (PRIORITY)
Dockerfile.binary   Product binary fallback
mkdocs.yml          MkDocs config (root — auto-discovered by mkdocs)
build.sh            Main entrypoint: build / scan / release / docs / registry / run
Makefile            Shortcut aliases for build.sh and compose commands
init.sh             First-run setup — run once after repo creation from template
```

---

## Future Roadmap

Items planned but not yet implemented. AI tools must NOT implement these speculatively
without explicit user instruction.

### Near-term
- **Multi-arch builds** — `linux/amd64` + `linux/arm64` via BuildKit `--platform`
- **Distroless/scratch runtime images** — separate build stage from runtime stage
- **Automated upstream sync** — scheduled CI job to detect new upstream releases and open PRs
- **SBOM diff on PRs** — compare SBOM between base and PR to surface new dependencies
- **`.local/docker-compose.run.yml` per-project override** — allow `docker-compose.run.override.yml`

### Medium-term
- **Reusable GitHub Actions** — extract CI steps into reusable composite actions
- **Helm chart testing** — `helm unittest` + `ct lint` in CI
- **Image provenance attestation** — full SLSA level 2 via `slsa-github-generator`
- **Dependabot for scanner versions** — auto-PR on new scanner image releases via `.cicd/scan-versions.env`

### Long-term
- **Policy-as-code** — OPA/Conftest policies for Helm + Dockerfile compliance checks
- **VEX documents** — Vulnerability Exploitability eXchange alongside SBOM attestations
- **Air-gapped registry mode** — all tool images mirrored to internal registry before use

---

*Version: 1.1.0 | Updated: 2026-03-26*
