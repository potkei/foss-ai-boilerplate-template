# Folder Structure

```
.agents/              # Shared AI hub — all tools read CONSTITUTION.md here
  skills/             # AI runbooks for CVE patching, releasing, etc.
.claude/commands/     # Claude Code slash commands
.cicd/                # All CI/CD pipeline configuration
  docker-resources/
    scripts/          # Build, scan, release scripts (stored as .sh.txt)
    secrets/          # Mount-only credentials (gitignored)
  jenkins_config.yml  # Jenkins declarative pipeline
  scan-versions.env   # Pinned scanner versions
  scan-exceptions.yml # Accepted CVE exceptions
.github/              # GitHub workflows, Copilot instructions
.cursor/              # Cursor AI rules
.codex/               # OpenAI Codex instructions
docs/                 # MkDocs documentation with Mermaid diagrams
helm/                 # Helm chart for Kubernetes deployment
patches/              # CVE patch files (source build only)
reports/              # Scan output (gitignored)
Dockerfile            # Source build — C/generic (PRIORITY)
Dockerfile.go         # Source build — Go-specific (PRIORITY)
Dockerfile.binary     # Binary fallback
docker-compose.build.yaml
docker-compose.scan.yml
docker-compose.scan.external.yml
docker-compose.registry.yml
docker-compose.docs.yml
init.sh               # First-run setup
build.sh              # Main build entrypoint
Makefile              # Shortcut aliases
CLAUDE.md             # AI constitution (Claude Code)
SECURITY.md           # Vulnerability disclosure policy
CHANGELOG.md          # Release changelog
```
