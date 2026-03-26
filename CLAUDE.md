# AI Constitution — FOSS Boilerplate Template

> **All AI assistants (Claude Code, Copilot, Cursor, Windsurf, Codex) must read and obey this
> constitution before taking any action in this repository.**
> Shared constitution lives at `.agents/CONSTITUTION.md`. This file is the Claude Code adapter.

---

## Article I — Purpose & Identity

This repository is a **managed fork** of an open source project. Its sole mission is to ship
security-patched container images faster than upstream by controlling our own build pipeline
and base images.

- We do **NOT** git-clone upstream. We **download official release archives** (tarball/zip).
- We do **NOT** maintain feature divergence — only security patches.
- All base images come from our own approved registries, never public upstream images.
- Every build produces an image traceable to a specific upstream version + our patch revision.

---

## Article II — Build Strategy Law

**SOURCE BUILD IS ALWAYS THE PRIORITY.**

| Strategy | Dockerfile | Status | Input |
|---|---|---|---|
| Source (compile from archive) | `Dockerfile` / `Dockerfile.go` | **PRIORITY** | Official release tarball |
| Binary (download pre-built) | `Dockerfile.binary` | **FALLBACK** | Official binary release |

**Mandates:**
1. Never delete either Dockerfile — both must remain functional at all times.
2. When asked to build without a strategy flag, always default to source build.
3. Binary fallback is a temporary state — resume source build ASAP.
4. Activating binary fallback requires tech lead approval + documented reason in `CHANGELOG.md`.
5. Single toggle: `BUILD_STRATEGY=source|binary` controls CI, local, and Helm consistently.

**Source build flow:**
```
Download archive → verify SHA256 (+ GPG optional) → extract
→ apply patches in order → compile → runtime image (approved base)
```

**Go-specific:** `go.sum` is never hand-patched — always regenerated via `go mod tidy` in Dockerfile.

---

## Article III — Versioning Convention

**Format:** `{upstream_foss_version}-r{N}`

```
6.0.0-r1    ← first revision on upstream 6.0.0
6.0.0-r2    ← second CVE fix, same upstream
6.1.0-r1    ← upstream bumped, reset revision to r1
```

- Git tag, Docker image tag, Helm `appVersion`, and `package.json` version all use this exact format.
- Revision resets to `r1` whenever the upstream version changes.
- CHANGELOG entry must map each `-rN` to the CVE ID(s) it addresses.

---

## Article IV — Branch Convention

```
main                           ← stable, always deployable, receives only from release/*
release/6.0.0-r1               ← release branch, name matches version tag exactly
hotfix/6.0.0-CVE-2024-1234     ← CVE patch branch → PR targets matching release branch
feature/description            ← feature → PR targets main or release branch
chore/description              ← maintenance → PR targets main
```

**Hotfix branch naming:** `hotfix/{upstream_version}-{CVE-ID}`
- Version prefix makes it immediately clear which release line the fix targets
- Multiple CVEs in one branch: `hotfix/6.0.0-CVE-2024-1234-CVE-2024-5678`
- Non-CVE hotfix: `hotfix/6.0.0-fix-description`

**Flow:**
```
hotfix/6.0.0-CVE-2024-1234 → PR + review + security sign-off → release/6.0.0-r2
                                                                        ↓ full pipeline passes
                                                                      main ← tag 6.0.0-r2
```

---

## Article V — Folder Structure Law

The following structure is canonical. Do not restructure without updating this document.

```
.agents/              # Shared AI hub — all tools read CONSTITUTION.md here
.claude/commands/     # Claude Code slash commands
.cicd/                # CI/CD pipeline only — Jenkins, scan configs, scripts, secrets
  scan-versions.env       Scanner version pins (shared: local + CI)
  scan-exceptions.yml     Accepted CVE exceptions with expiry (CI-enforced)
  jenkins_config.yml      Jenkins pipeline definition
  docker-resources/       Scripts (.sh.txt) and secrets (mount-only, gitignored)
.local/               # Local dev tooling — compose files + tool Dockerfiles (NOT CI/CD)
  docker-compose.build.yaml
  docker-compose.run.yml
  docker-compose.scan.yml
  docker-compose.scan.external.yml
  docker-compose.registry.yml
  docker-compose.docs.yml
  Dockerfile.docs
  Dockerfile.checkov
  Dockerfile.semgrep
.deploy/              # All deployment manifests
.github/              # GitHub workflows, templates, Copilot instructions
.cursor/              # Cursor AI rules
.codex/               # OpenAI Codex instructions
docs/                 # MkDocs documentation with Mermaid diagrams
helm/                 # Helm chart
patches/              # CVE patch files (source build only)
projects/             # Monorepo subprojects (if monorepo mode)
reports/              # Scan output (gitignored)
Dockerfile            # Source build — C/generic (PRIORITY)
Dockerfile.go         # Source build — Go-specific (PRIORITY)
Dockerfile.binary     # Binary fallback
mkdocs.yml            # MkDocs config — stays at root (auto-discovered by mkdocs)
init.sh               # First-run setup — run once after repo creation from template
build.sh              # Main entrypoint for all build/scan/release operations
Makefile              # Shortcut aliases
CLAUDE.md             # This file
SECURITY.md           # Vulnerability disclosure policy
CHANGELOG.md          # Must update on every release
```

**Separation law:**
- `.cicd/` — CI/CD pipeline configuration only. No compose files. No tool Dockerfiles.
- `.local/` — local dev tooling only. Never referenced by Jenkins or remote CI.
- `Dockerfile`, `Dockerfile.go`, `Dockerfile.binary` — always at repo root. Never moved.
- `mkdocs.yml` — always at repo root. MkDocs auto-discovers it there.

---

## Article VI — Security Mandates

1. **Secrets are never committed.** `.cicd/docker-resources/secrets/` is mount-only, fully gitignored.
2. **CVE patches go to source build first.** Binary fallback may lag one release cycle maximum.
3. **All images must pass CVE scan before push.** Exceptions documented in `.cicd/scan-exceptions.yml` with expiry date and owner.
4. **Base image versions are pinned.** No `latest` tags in Dockerfiles — use digest or explicit version.
5. **No secrets in build args.** Use Docker secrets or runtime environment injection.
6. **SBOM generated on every release** via Syft (CycloneDX format), attached as image attestation.
7. **Images signed on every release** via Cosign.
8. **GPG signature verified** for upstream archives where available.

---

## Article VII — Patch Management Law

**Naming convention:**
```
patches/
    0001-CVE-2024-1234-fix-buffer-overflow.patch
    0002-CVE-2024-5678-fix-path-traversal.patch
    0003-NONCVE-fix-memory-leak.patch
```

**Required patch file header:**
```patch
# CVE:           CVE-2024-1234
# Upstream-PR:   https://github.com/upstream/pull/456  (or NONE / pending)
# Upstream-Fix:  not-fixed | fixed-in-6.2.0 | wont-fix | pending
# Keep-on-sync:  yes | no | check
# Contributed:   YYYY-MM-DD  (date we submitted upstream PR)
# Notes:         Drop when upgrading to >= 6.2.0
```

**Patch application in Dockerfile:**
```dockerfile
RUN for p in $(ls /patches/*.patch | sort); do patch -p1 < "$p" || exit 1; done
```

**`Keep-on-sync` values:**
- `no` — upstream fixed it; drop this patch when upgrading to that version
- `yes` — custom change, never upstream; always re-apply on version bump
- `check` — upstream PR open; verify on sync whether it merged

---

## Article VIII — Team Rules

**Review & Approval:**
- Minimum 1 reviewer approval before merge to any branch
- CVE patches require security team sign-off before merge to release branch
- Binary fallback activation requires tech lead approval + CHANGELOG entry

**CVE Response SLA:**
| Severity | CVSS | Patch SLA | Binary fallback if blocked |
|---|---|---|---|
| Critical | ≥ 9.0 | 24 hours | Yes |
| High | 7.0–8.9 | 72 hours | After 72h |
| Medium | 4.0–6.9 | Next release | No |
| Low | < 4.0 | Next release | No |

**Dependency Blocker & Cooldown:**
- Document blocker in CHANGELOG under `[BLOCKED]`: CVE ID, blocking dep, expected resolution, owner
- Wait 3 days (72 hours) after upstream publishes before adopting (let community surface regressions)
- Exception: critical CVE — adopt immediately after checksum verified
- If blocker resolves: re-run full pipeline from scratch (no cached layers)

**Re-run Tests When Changed:**
| Changed path | Action |
|---|---|
| `patches/**` | Full source build + all tests |
| `Dockerfile` or `Dockerfile.go` | Full source build + all tests |
| `Dockerfile.binary` | Binary build + all tests |
| `helm/**` | Helm lint + deploy test |
| `.cicd/docker-resources/scripts/**` | All pipeline stages |
| `.cicd/scan-versions.env` | Re-run all scans with new scanner versions |
| `.local/Dockerfile.*` | Rebuild affected tool image + re-run its scan stage |
| `.local/docker-compose.*.yml` | Validate compose config + smoke test affected stack |
| `projects/<name>/**` (monorepo) | That subproject's pipeline only |

Always re-run full pipeline: merging to `main`, applying CVE patch, switching `BUILD_STRATEGY`.

**Never skip tests** — do not use `--no-verify`, skip flags, or bypass scan gates without explicit
security team approval documented in `CHANGELOG.md`.

---

## Article IX — AI Behavior Directives

| Trigger | Action |
|---|---|
| Asked to build | Default to source build (`Dockerfile`) |
| Asked to run locally | Use `.local/docker-compose.run.yml` |
| Asked to patch a CVE | Create `hotfix/{version}-{CVE-ID}` branch, follow `.agents/skills/cve-patch.md` |
| Asked to onboard a new FOSS project | Follow `.agents/skills/onboard-foss-project.md` |
| Asked to switch build strategy | Follow `.agents/skills/build-strategy-switch.md` |
| Asked to release | Follow `.agents/skills/release.md` |
| Asked to sync upstream | Follow `.agents/skills/upstream-sync.md` |
| Asked to contribute patch upstream | Follow `.agents/skills/upstream-contribute.md` |
| Asked to run security scan | Follow `.agents/skills/security-scan.md` |
| Editing a Dockerfile | Preserve all variants (source, Go, binary) |
| Noticing a `latest` tag | Flag it and suggest pinned version |
| Finding secrets in code | Refuse to commit; alert user immediately |
| Go project CVE in dependency | Follow `.agents/skills/go-dependency-patch.md` |
| Editing `.local/` tool Dockerfiles | Keep `python:*-slim` + uv pattern; never use fat images |
| Adding new `.local/` compose service | Always add `pull_policy: missing`; add `image:` if `build:` is used |

**Programming Language Version Policy:**
- Always use the latest stable version of each language (Python, Go, Node, etc.) in Dockerfiles
- Before pinning a version, verify it is the current stable release
- If the latest version causes a build failure, fall back to the last known-good version and ask the user
- Never silently pin an old version — always inform the user and explain why

**Prohibited actions:**
- Do not add features unless explicitly asked
- Do not refactor code unless explicitly asked
- Do not merge or push without explicit human confirmation
- Do not modify `.cicd/docker-resources/secrets/` contents
- Do not bypass checksum verification steps
- Do not use `latest` tags in any Dockerfile
- Do not skip tests, scan gates, or verification steps
- Do not move `Dockerfile`, `Dockerfile.go`, `Dockerfile.binary` out of repo root
- Do not move `mkdocs.yml` out of repo root
- Do not place compose files or tool Dockerfiles in `.cicd/`

---

## Article X — Monorepo Addendum

When operating in monorepo mode (`projects/` directory exists):
- Root `CLAUDE.md` governs all subprojects
- Subprojects may have their own `CLAUDE.md` to override project-specific rules only
- Root `.cicd/` provides shared scripts; subproject `.cicd/` extends them
- CI detects monorepo mode by presence of `projects/` directory and generates parallel stages
- Run `make onboard` or `./projects/build-all.sh --add` to add a new subproject

---

## Article XI — Future Roadmap

Items planned but not yet implemented. **Do NOT implement speculatively** — wait for explicit
user instruction. These entries exist to give AI tools context when users ask "what's next".

**Near-term:**
- Multi-arch builds — `linux/amd64` + `linux/arm64` via BuildKit `--platform`
- Distroless/scratch runtime images — separate build stage from runtime stage in product Dockerfiles
- Automated upstream sync — scheduled CI job detecting new upstream releases, opening PRs automatically
- SBOM diff on PRs — compare SBOM between base and PR branch to surface new transitive dependencies
- `.local/docker-compose.run.override.yml` pattern — per-project runtime config override

**Medium-term:**
- Reusable GitHub Actions — extract CI steps into reusable composite actions for downstream repos
- Helm chart testing — `helm unittest` + `ct lint` in CI pipeline
- Image provenance attestation — full SLSA level 2 via `slsa-github-generator`
- Dependabot for scanner versions — auto-PR when scanner images in `.cicd/scan-versions.env` have updates

**Long-term:**
- Policy-as-code — OPA/Conftest policies for Helm + Dockerfile compliance checks
- VEX documents — Vulnerability Exploitability eXchange alongside SBOM attestations
- Air-gapped registry mode — all tool images mirrored to internal registry before use
- Template sync bot — propagate template fixes to downstream repos via automated PRs

---

*Constitution version: 1.1.0 | Last updated: 2026-03-26*
