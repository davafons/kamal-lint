# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `--include-kamal-errors` flag to opt-in to surfacing errors from Kamal's own loader (off by default; use `kamal config` for parse-time checks).

### Fixed
- `image-registry-mismatch` no longer false-positives when `registry.server` is set to Docker Hub (`docker.io`, `index.docker.io`, `registry.hub.docker.com`) and the image lacks an explicit registry prefix — Docker Hub resolves unprefixed images automatically.

### Internal
- Renamed `LICENSE` → `MIT-LICENSE` to match Kamal's convention.
- Added `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.ruby-version`, `bin/release`.
- Added `Release` GitHub Actions workflow for tag-triggered publishing via RubyGems trusted publishing (OIDC).
- Added `actionlint` and `zizmor` workflow security audits in CI.
- Added `dependabot.yml` for weekly bundler + GitHub Actions updates.
- Added PR template and issue templates (bug report, new check proposal).

## [0.1.0] - 2026-05-11

### Added
- Initial release.
- 16 checks across reference integrity, coherence, and smells:
  - `secret-not-declared`
  - `accessory-role-undefined`
  - `proxy-host-not-in-role`
  - `image-registry-mismatch`
  - `builder-registry-secret-undeclared`
  - `ssl-without-host`
  - `empty-web-role`
  - `traefik-legacy-keys` (autofixable)
  - `boot-limit-exceeds-hosts`
  - `accessory-host-undefined`
  - `missing-service-name` (autofixable)
  - `kamal-secrets-not-gitignored` (autofixable)
  - `secret-in-env-clear`
  - `missing-proxy-healthcheck`
  - `accessory-image-latest`
  - `registry-without-explicit-server`
- Three output formatters: `human`, `json`, `github` (GitHub Actions annotations).
- `--fix` for the safe autofix subset.
- `-d/--destination` for linting destination override files.
- Auto-detection of installed Kamal version with version-gated checks.
- `kamal-lint` GitHub Action (composite) for one-line CI integration.

[Unreleased]: https://github.com/davafons/kamal-lint/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/davafons/kamal-lint/releases/tag/v0.1.0
