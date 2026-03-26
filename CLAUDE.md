# Claude Code — FOSS Boilerplate

> **Read `.agents/CONSTITUTION.md` first.** This file is the Claude Code adapter only.
> Full rules, folder map, team SLAs, patch format, and roadmap live in CONSTITUTION.md.

---

## Critical Rules (quick ref — details in CONSTITUTION.md)

- **Source build always first**: `Dockerfile` / `Dockerfile.go` — never default to binary
- **Version format**: `{upstream}-r{N}` — e.g. `6.0.0-r1` → `6.0.0-r2` → `6.1.0-r1`
- **Hotfix branches**: `hotfix/{upstream_version}-{CVE-ID}` — e.g. `hotfix/6.0.0-CVE-2024-1234`
- **Script files**: `.sh.txt` extension only — enterprise policy blocks `.sh`
- **No `latest` tags** in any Dockerfile — pin to explicit version or digest
- **No push / merge** without explicit human confirmation

---

## Folder Separation (strict)

| Path | Purpose |
|---|---|
| `.cicd/` | CI/CD pipeline only — Jenkins, scan configs, `.env`, secrets |
| `.local/` | Local dev only — compose files, tool Dockerfiles |
| `Dockerfile`, `Dockerfile.go`, `Dockerfile.binary` | Always at repo root — never moved |
| `mkdocs.yml` | Always at repo root — MkDocs auto-discovers it |

`.cicd/scan-versions.env` is shared between local and CI — do not duplicate it.

---

## AI Behavior Directives

| Trigger | Action |
|---|---|
| Asked to build | Default to source build (`Dockerfile`) |
| Asked to run locally | Use `.local/docker-compose.run.yml` |
| Asked to patch a CVE | Branch `hotfix/{version}-{CVE-ID}`, follow `.agents/skills/cve-patch.md` |
| Asked to onboard a new FOSS project | Follow `.agents/skills/onboard-foss-project.md` |
| Asked to switch build strategy | Follow `.agents/skills/build-strategy-switch.md` |
| Asked to release | Follow `.agents/skills/release.md` |
| Asked to sync upstream | Follow `.agents/skills/upstream-sync.md` |
| Asked to contribute patch upstream | Follow `.agents/skills/upstream-contribute.md` |
| Asked to run security scan | Follow `.agents/skills/security-scan.md` |
| Go project CVE in dependency | Follow `.agents/skills/go-dependency-patch.md` |
| Editing a Dockerfile | Preserve all three variants (source, Go, binary) |
| Noticing a `latest` tag | Flag it and suggest pinned version |
| Finding secrets in code | Refuse to commit; alert user immediately |
| Editing `.local/` tool Dockerfiles | Keep `python:*-slim` + `uv` pattern — never fat images |
| Adding a new `.local/` compose service | Add `pull_policy: missing`; add `image:` if `build:` is used |

---

## Programming Language Version Policy

- Use the **latest stable** version of each language in Dockerfiles
- Verify before pinning that it is the current stable release
- If latest causes a build failure, fall back to last known-good and tell the user
- Never silently pin an old version — always inform and explain

---

## Prohibited

- No unrequested features, refactoring, or "improvements"
- No merge or push without explicit human confirmation
- No bypassing checksum verification or scan gates
- No `latest` tags in any Dockerfile
- No `.sh` / `.py` / `.bat` script files committed (use `.txt`)
- No compose files or tool Dockerfiles placed in `.cicd/`
- No moving `Dockerfile*` out of repo root
- No moving `mkdocs.yml` out of repo root
- No touching `.cicd/docker-resources/secrets/`

---

*Constitution version: 1.2.0 | Last updated: 2026-03-26*
