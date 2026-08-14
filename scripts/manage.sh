#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"
README_FILE="${ROOT_DIR}/README.md"

usage() {
  cat <<'USAGE'
Usage: scripts/manage.sh <command> [args]

Commands:
  clean                      Clean Rust workspace build artifacts
  build                      Build repository code artifacts
  run <dev|test|prod>        Run repository workflows by mode
  release                    Run release readiness checks
  version <bump|minor|major> Increment version in VERSION and README
  help                       Show this help message
USAGE
}

ensure_version_file() {
  if [[ ! -f "${VERSION_FILE}" ]]; then
    echo "0.1.0" >"${VERSION_FILE}"
  fi
}

read_version() {
  ensure_version_file
  local version
  version="$(tr -d '[:space:]' <"${VERSION_FILE}")"
  if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: VERSION must be in MAJOR.MINOR.PATCH format" >&2
    exit 1
  fi
  echo "${version}"
}

sync_readme_version() {
  local new_version="$1"
  if [[ -f "${README_FILE}" ]]; then
    sed -i -E "s/^Current Version: .*/Current Version: ${new_version}/" "${README_FILE}"
  fi
}

set_version() {
  local new_version="$1"
  printf '%s\n' "${new_version}" >"${VERSION_FILE}"
  sync_readme_version "${new_version}"
  echo "Version updated to ${new_version}"
}

bump_version() {
  local kind="$1"
  local current major minor patch
  current="$(read_version)"
  IFS='.' read -r major minor patch <<<"${current}"

  case "${kind}" in
    bump)
      patch=$((patch + 1))
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    *)
      echo "Error: version must be one of bump|minor|major" >&2
      exit 1
      ;;
  esac

  set_version "${major}.${minor}.${patch}"
}

cmd_clean() {
  if [[ -d "${ROOT_DIR}/rust-continuation-laboratory" ]]; then
    (cd "${ROOT_DIR}/rust-continuation-laboratory" && bash ./clean-all.sh)
  fi
  echo "Clean complete"
}

cmd_build() {
  if [[ -d "${ROOT_DIR}/rust-continuation-laboratory" ]]; then
    (cd "${ROOT_DIR}/rust-continuation-laboratory" && cargo build --workspace)
  fi
  echo "Build complete"
}

cmd_run() {
  local mode="${1:-}"
  case "${mode}" in
    dev)
      (cd "${ROOT_DIR}" && python -m http.server 8000)
      ;;
    test)
      (cd "${ROOT_DIR}/rust-continuation-laboratory" && cargo test --workspace)
      ;;
    prod)
      (cd "${ROOT_DIR}" && bash ./generators/run_samples.sh)
      ;;
    *)
      echo "Error: run mode must be one of dev|test|prod" >&2
      exit 1
      ;;
  esac
}

cmd_release() {
  cmd_build
  (cd "${ROOT_DIR}/rust-continuation-laboratory" && cargo test --workspace)
  echo "Release checks complete for version $(read_version)"
}

main() {
  local command="${1:-help}"
  case "${command}" in
    clean)
      shift
      cmd_clean "$@"
      ;;
    build)
      shift
      cmd_build "$@"
      ;;
    run)
      shift
      cmd_run "$@"
      ;;
    release)
      shift
      cmd_release "$@"
      ;;
    version)
      shift
      if [[ "$#" -ne 1 ]]; then
        echo "Error: version command requires one argument" >&2
        exit 1
      fi
      bump_version "$1"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "Error: unknown command '${command}'" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
