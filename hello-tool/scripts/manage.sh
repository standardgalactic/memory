#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
VERSION_FILE="${ROOT_DIR}/VERSION"
README_FILE="${ROOT_DIR}/README.md"
export GOTOOLCHAIN="${GOTOOLCHAIN:-go1.26.6}"

usage() {
  cat <<'USAGE'
Usage: scripts/manage.sh <command> [args]

Commands:
  doctor                      Run toolchain and module health checks
  clean                       Remove build artifacts
  build                       Build binary into dist/
  run                         Run the CLI locally
  test                        Run go test
  release                     Run doctor, test, and build
  version <bump|minor|major>  Increment version and sync README
  help                        Show this help
USAGE
}

read_version() {
  if [[ ! -f "${VERSION_FILE}" ]]; then
    echo "Error: VERSION file not found" >&2
    exit 1
  fi
  local version
  version="$(tr -d '[:space:]' <"${VERSION_FILE}")"
  if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: VERSION must be MAJOR.MINOR.PATCH" >&2
    exit 1
  fi
  echo "${version}"
}

sync_readme_version() {
  local new_version="$1"
  sed -i -E "s/^Current version: .*/Current version: ${new_version}/" "${README_FILE}"
}

set_version() {
  local new_version="$1"
  printf '%s\n' "${new_version}" >"${VERSION_FILE}"
  sync_readme_version "${new_version}"
  echo "Version updated to ${new_version}"
}

cmd_version() {
  local kind="${1:-}"
  local current major minor patch
  current="$(read_version)"
  IFS='.' read -r major minor patch <<<"${current}"

  case "${kind}" in
    bump) patch=$((patch + 1)) ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    major) major=$((major + 1)); minor=0; patch=0 ;;
    *)
      echo "Error: version must be bump|minor|major" >&2
      exit 1
      ;;
  esac

  set_version "${major}.${minor}.${patch}"
}

cmd_doctor() {
  cd "${ROOT_DIR}"
  go version
  go env GOTOOLCHAIN GOPROXY GOSUMDB
  go list -m -u all
  go mod graph | grep 'golang.org/x/mod'
  if ! command -v govulncheck >/dev/null 2>&1; then
    echo "Error: govulncheck is required; install with: GOTOOLCHAIN=${GOTOOLCHAIN} go install golang.org/x/vuln/cmd/govulncheck@v1.1.4" >&2
    exit 1
  fi
  govulncheck ./...
}

cmd_clean() {
  rm -rf "${DIST_DIR}"
  echo "Clean complete"
}

cmd_build() {
  cd "${ROOT_DIR}"
  mkdir -p "${DIST_DIR}"
  local version
  version="$(read_version)"
  go build -trimpath -ldflags "-s -w -X main.version=${version}" -o "${DIST_DIR}/hello-tool_${version}" ./...
  echo "Built ${DIST_DIR}/hello-tool_${version}"
}

cmd_run() {
  cd "${ROOT_DIR}"
  local version
  version="$(read_version)"
  go run -ldflags "-X main.version=${version}" .
}

cmd_test() {
  cd "${ROOT_DIR}"
  go test ./...
}

cmd_release() {
  cmd_doctor
  cmd_test
  cmd_build
}

main() {
  local command="${1:-help}"
  case "${command}" in
    doctor) shift; cmd_doctor "$@" ;;
    clean) shift; cmd_clean "$@" ;;
    build) shift; cmd_build "$@" ;;
    run) shift; cmd_run "$@" ;;
    test) shift; cmd_test "$@" ;;
    release) shift; cmd_release "$@" ;;
    version)
      shift
      if [[ "$#" -ne 1 ]]; then
        echo "Error: version requires one argument" >&2
        exit 1
      fi
      cmd_version "$1"
      ;;
    help|-h|--help) usage ;;
    *)
      echo "Error: unknown command '${command}'" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
