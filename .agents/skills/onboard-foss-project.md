# Skill: Onboard FOSS Project

Scaffold a new FOSS project into this boilerplate template from scratch.

## Purpose
Walk through onboarding a new upstream FOSS project: collect details, translate script files
from `.txt` to executable, fill in all template placeholders, create initial release branch.

## Prerequisites
- Repository created from template: `gh repo create <name> --template potkei/foss-ai-boilerplate-template`
- User has upstream project details ready (or can look them up)

## Steps

### Step 1 — Collect Project Details
Ask the user these questions in order:

```
1.  Repo mode?
    → polyrepo  (this repo = one FOSS project)
    → monorepo  (adding under projects/<name>/)

2.  FOSS project name?
    → e.g. nginx, redis, curl, zip

3.  Upstream version to pin?
    → e.g. 1.27.3

4.  Archive download URL?
    → e.g. https://nginx.org/download/nginx-1.27.3.tar.gz

5.  Archive format?
    → tar.gz / tar.bz2 / tar.xz / zip

6.  SHA256 checksum?
    → paste from upstream release page

7.  GPG signature available?
    → yes (provide .asc URL) / no

8.  Project language?
    → c / c++ / go / java / python / other

9.  License?
    → e.g. BSD-2-Clause, Apache-2.0, GPL-2.0

10. Default build strategy?
    → source (default) / binary

11. Container registry namespace?
    → e.g. registry.company.com/infra

12. Kubernetes namespace?
    → e.g. infra, platform

13. Monorepo only: which root directory?
    → e.g. projects/nginx
```

### Step 2 — Translate Script Files
All scripts are stored as `.txt` to bypass enterprise file extension blocks.
Translate them back to original extensions:

```bash
# Find all .sh.txt files and translate
find . -name "*.sh.txt" | while read f; do
  target="${f%.txt}"
  cp "$f" "$target"
  chmod +x "$target"
  echo "Translated: $f → $target"
done

# Find all .py.txt files and translate
find . -name "*.py.txt" | while read f; do
  target="${f%.txt}"
  cp "$f" "$target"
  chmod +x "$target"
  echo "Translated: $f → $target"
done

# Find all .bat.txt files and translate (Windows)
find . -name "*.bat.txt" | while read f; do
  target="${f%.txt}"
  cp "$f" "$target"
  echo "Translated: $f → $target"
done
```

> Note: The `.txt` originals are kept — they are the source of truth in the repo.
> The translated files are gitignored (listed in `.gitignore`).

### Step 3 — Fill Template Placeholders
Update these files with collected answers:

**`package.json`:**
```json
{
  "name": "<foss-name>-fork",
  "version": "<upstream_version>-r1",
  "upstream": {
    "name": "<foss-name>",
    "version": "<upstream_version>",
    "archiveUrl": "<archive_url>",
    "archiveFormat": "<format>",
    "sha256": "<sha256>",
    "gpgUrl": "<gpg_url or null>",
    "language": "<language>",
    "license": "<license>"
  },
  "registry": "<registry_namespace>",
  "k8sNamespace": "<k8s_namespace>"
}
```

**`Dockerfile`** (or `Dockerfile.go` for Go projects):
- Set `ARG UPSTREAM_ARCHIVE_URL=<archive_url>`
- Set `ARG UPSTREAM_SHA256=<sha256>`
- Set `ARG UPSTREAM_VERSION=<upstream_version>`
- Set base image to approved internal registry

**`Dockerfile.binary`:**
- Set `ARG BINARY_URL` and `ARG BINARY_SHA256`

**`helm/Chart.yaml`:**
- Set `name: <foss-name>-fork`
- Set `version: 1.0.0`
- Set `appVersion: <upstream_version>-r1`

**`helm/values.yaml`:**
- Set `image.repository: <registry_namespace>/<foss-name>`
- Set `image.tag: <upstream_version>-r1`

**`CHANGELOG.md`:**
```markdown
## [<upstream_version>-r1] - <today>
### Initial
- Forked from upstream <foss-name> <upstream_version>
- Source: <archive_url>
- SHA256: <sha256>
```

**`README.md`:** Replace all `<PLACEHOLDER>` values.

**`sonar-project.properties`:**
- Set `sonar.projectKey=<foss-name>-fork`
- Set `sonar.projectName=<foss-name> (patched fork)`

### Step 4 — Create Initial Release Branch
```bash
git checkout -b release/<upstream_version>-r1
git add .
git commit -m "chore: initial onboard of <foss-name> <upstream_version>"
git push -u origin release/<upstream_version>-r1
```

### Step 5 — Verify Setup
```bash
# Dry run — verify no patches fail (patches/ is empty at this point, so this is a no-op)
./patches/verify.sh

# Lint Dockerfiles
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile.binary

# Verify build compiles (source build)
BUILD_STRATEGY=source ./build.sh
```

## Validation
- [ ] All placeholder values filled in `package.json`, Dockerfiles, Helm, README
- [ ] Script `.txt` files translated to executable equivalents
- [ ] `release/<upstream_version>-r1` branch created and pushed
- [ ] Dockerfiles pass hadolint
- [ ] Source build compiles successfully
- [ ] CHANGELOG has initial entry

## Monorepo Note
If repo mode = monorepo, run `monorepo-add-project` skill instead,
which places the project under `projects/<foss-name>/`.

## Related
- Skill: `monorepo-add-project.md`
- Doc: `docs/onboarding.md`
- Script: `init.sh` (wrapper that calls this skill interactively)
