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
main                    ← stable, always deployable, receives only from release/*
release/6.0.0-r1        ← release branch, name matches version tag exactly
fix/CVE-2024-1234       ← CVE patch branch → PR targets release branch
feat/description        ← feature → PR targets main or release branch
chore/description       ← maintenance → PR targets main
```

**Flow:**
```
fix/CVE-2024-1234 → PR + review + security sign-off → release/6.0.0-r1
                                                              ↓ full pipeline passes
                                                            main ← tag 6.0.0-r1
```

---

## Article V — Folder Structure Law

The following structure is canonical. Do not restructure without updating this document.

```
.agents/              # Shared AI hub — all tools read CONSTITUTION.md here
.claude/commands/     # Claude Code slash commands
.cicd/                # All CI/CD pipeline configuration
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
docker-compose.build.yaml
docker-compose.scan.yml
docker-compose.scan.external.yml
docker-compose.registry.yml
docker-compose.docs.yml
init.sh               # First-run setup — run once after repo creation from template
build.sh              # Main entrypoint for all build/scan/release operations
Makefile              # Shortcut aliases
CLAUDE.md             # This file
SECURITY.md           # Vulnerability disclosure policy
CHANGELOG.md          # Must update on every release
```

---

## Article VI — Security Mandates

1. **Secrets are never committed.** `.cicd/docker-resources/secrets/` is mount-only, fully gitignored.
2. **CVE patches go to source build first.** Binary fallback may lag one release cycle maximum.
3. **All images must pass CVE scan before push.** Exceptions documented in `.trivyignore` with expiry.
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
| `projects/<name>/**` (monorepo) | That subproject's pipeline only |

Always re-run full pipeline: merging to `main`, applying CVE patch, switching `BUILD_STRATEGY`.

---

## Article IX — AI Behavior Directives

| Trigger | Action |
|---|---|
| Asked to build | Default to source build (`Dockerfile`) |
| Asked to patch a CVE | Follow `.agents/skills/cve-patch.md` |
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

**Prohibited actions:**
- Do not add features unless explicitly asked
- Do not refactor code unless explicitly asked
- Do not merge or push without explicit human confirmation
- Do not modify `.cicd/docker-resources/secrets/` contents
- Do not bypass checksum verification steps
- Do not use `latest` tags in any Dockerfile

---

## Article X — Monorepo Addendum

When operating in monorepo mode (`projects/` directory exists):
- Root `CLAUDE.md` governs all subprojects
- Subprojects may have their own `CLAUDE.md` to override project-specific rules only
- Root `.cicd/` provides shared scripts; subproject `.cicd/` extends them
- CI detects monorepo mode by presence of `projects/` directory and generates parallel stages
- Run `make onboard` or `./projects/build-all.sh --add` to add a new subproject

---

*Constitution version: 1.0.0 | Last updated: 2026-03-25*
