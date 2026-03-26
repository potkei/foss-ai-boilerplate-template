#!/usr/bin/env bash
# =============================================================================
# INIT — First-run setup after creating repo from template
# Translates .sh.txt scripts to executable .sh, creates required directories,
# and validates prerequisites are installed.
# Run once: ./init.sh
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================================="
echo " FOSS Boilerplate — First-Run Setup"
echo "==================================================="
echo ""

# -------------------------------------------------------------------------
# 1. Validate prerequisites
# -------------------------------------------------------------------------
echo "--- Checking prerequisites ---"

MISSING=()

command -v docker  >/dev/null 2>&1 || MISSING+=("docker")
command -v git     >/dev/null 2>&1 || MISSING+=("git")
command -v jq      >/dev/null 2>&1 || MISSING+=("jq")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: Missing required tools: ${MISSING[*]}"
  echo "Install them and re-run ./init.sh"
  exit 1
fi

# Optional tools — warn but don't block
command -v cosign  >/dev/null 2>&1 || echo "  WARN: cosign not found (needed for image signing)"
command -v helm    >/dev/null 2>&1 || echo "  WARN: helm not found (needed for Helm chart operations)"

echo "  All required tools present."
echo ""

# -------------------------------------------------------------------------
# 2. Create required directories
# -------------------------------------------------------------------------
echo "--- Creating directories ---"

for dir in patches reports docs helm; do
  if [ ! -d "${ROOT_DIR}/${dir}" ]; then
    mkdir -p "${ROOT_DIR}/${dir}"
    echo "  Created: ${dir}/"
  else
    echo "  Exists:  ${dir}/"
  fi
done

# Ensure reports is gitignored but dir exists
touch "${ROOT_DIR}/reports/.gitkeep"
touch "${ROOT_DIR}/patches/.gitkeep"

echo ""

# -------------------------------------------------------------------------
# 3. Translate .txt script files to executable originals
# -------------------------------------------------------------------------
echo "--- Translating script files (.sh.txt -> .sh) ---"

TRANSLATED=0

find "${ROOT_DIR}" -name "*.sh.txt" | sort | while read -r f; do
  target="${f%.txt}"
  if [ ! -f "$target" ]; then
    cp "$f" "$target"
    chmod +x "$target"
    echo "  Translated: $(realpath --relative-to="${ROOT_DIR}" "$target")"
  else
    echo "  Exists:     $(realpath --relative-to="${ROOT_DIR}" "$target")"
  fi
done

find "${ROOT_DIR}" -name "*.py.txt" | sort | while read -r f; do
  target="${f%.txt}"
  if [ ! -f "$target" ]; then
    cp "$f" "$target"
    chmod +x "$target"
    echo "  Translated: $(realpath --relative-to="${ROOT_DIR}" "$target")"
  fi
done

echo ""

# -------------------------------------------------------------------------
# 4. Make root scripts executable
# -------------------------------------------------------------------------
echo "--- Setting executable permissions ---"

for script in build.sh init.sh; do
  if [ -f "${ROOT_DIR}/${script}" ]; then
    chmod +x "${ROOT_DIR}/${script}"
    echo "  chmod +x: ${script}"
  fi
done

echo ""

# -------------------------------------------------------------------------
# 5. Verify Docker is running
# -------------------------------------------------------------------------
echo "--- Checking Docker daemon ---"
if docker info >/dev/null 2>&1; then
  echo "  Docker daemon is running."
else
  echo "  WARN: Docker daemon not reachable. Start Docker before building."
fi

echo ""
echo "==================================================="
echo " Init complete!"
echo ""
echo " Next steps:"
echo "   1. Run the onboard skill to configure for your FOSS project"
echo "   2. Or manually update Dockerfiles and package.json"
echo "   3. Run: ./build.sh          (source build)"
echo "   4. Run: ./build.sh --scan   (security scans)"
echo "==================================================="
