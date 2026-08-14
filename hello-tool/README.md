# hello-tool

Simple Go CLI starter with secure toolchain defaults and maintenance scripts.

Current version: 0.1.0

## Quickstart

```bash
go env -w GOTOOLCHAIN=go1.26.6
go get golang.org/x/mod@v0.40.0
```

## Management script

```bash
./scripts/manage.sh doctor
./scripts/manage.sh clean
./scripts/manage.sh test
./scripts/manage.sh build
./scripts/manage.sh run
./scripts/manage.sh release
./scripts/manage.sh version bump
./scripts/manage.sh version minor
./scripts/manage.sh version major
```
