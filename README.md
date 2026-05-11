<h1 align="center">kamal-lint</h1>

<p align="center">
  <a href="https://rubygems.org/gems/kamal-lint"><img src="https://img.shields.io/gem/v/kamal-lint" alt="Gem Version"></a>
  <a href="https://github.com/davafons/kamal-lint/actions/workflows/ci.yml"><img src="https://github.com/davafons/kamal-lint/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/davafons/kamal-lint/blob/main/MIT-LICENSE"><img src="https://img.shields.io/github/license/davafons/kamal-lint" alt="License"></a>
  <a href="https://rubygems.org/gems/kamal-lint"><img src="https://img.shields.io/gem/dt/kamal-lint" alt="Downloads"></a>
</p>

Static linter for [Kamal](https://kamal-deploy.org) `config/deploy.yml`. Catches cross-section bugs and smells that Kamal itself silently allows — undeclared secrets, accessory/role mismatches, registry inconsistencies, and more — before a single SSH connection happens.

```
$ bundle exec kamal-lint
kamal-lint 0.1.0 · kamal 2.11.0 detected
  config:      config/deploy.yml

✖ error   config/deploy.yml:9
    env.secret references `RAILS_MASTER_KEY` but it isn't declared in .kamal/secrets
    [secret-not-declared]

⚠ warning config/deploy.yml:18 (autofixable)
    `traefik:` block is Kamal 1.x legacy and is ignored in Kamal 2+; use `proxy:` instead
    [traefik-legacy-keys]

Summary: 1 error, 1 warning, 1 autofixable
```

## Why

Kamal's own loader only checks "does this YAML parse into my schema?" It happily accepts a config that references secrets you never declared, points at registries you don't use, names roles that don't exist, or still uses Kamal 1.x `traefik:` keys. By the time you find out, you've already shipped a broken deploy.

`kamal-lint` runs in CI (or pre-commit) and catches these before they hit production.

## Install

Add to your project's `Gemfile`:

```ruby
group :development, :test do
  gem "kamal-lint", require: false
end
```

Then:

```bash
bundle install
bundle exec kamal-lint
```

Or install globally:

```bash
gem install kamal-lint
kamal-lint
```

## Usage

```
bundle exec kamal-lint [OPTIONS]

  -c, --config-file PATH    Path to deploy.yml (default: config/deploy.yml)
  -d, --destination NAME    Lint with destination override applied
                              (e.g. -d production → config/deploy.production.yml)
  -f, --format FORMAT       human (default) | json | github
      --fail-on LEVEL       error | warning (default) | info
      --fix                 Apply safe autofixes in-place
      --kamal-version VER   Override detected Kamal version
      --include-kamal-errors  Also surface errors from Kamal's own loader
                                (off by default; use `kamal config` for that)
      --no-color            Disable colored output
      --list-checks         Print all registered checks
      --version             Print kamal-lint version
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0`  | No findings at or above `--fail-on` severity |
| `1`  | Findings present at or above `--fail-on` severity |
| `2`  | Config file not found / unreadable |

## Checks

| ID | Severity | Autofixable | What it catches |
|---|---|---|---|
| `secret-not-declared` | error | | `env.secret` references a key absent from `.kamal/secrets` |
| `accessory-role-undefined` | error | | accessory `roles:` lists a role not in `servers` |
| `role-hosts-empty` | error | | a role under `servers:` has no hosts (silent no-op deploy) |
| `image-registry-mismatch` | error | | `image:` registry prefix ≠ `builder.registry.server` |
| `builder-registry-secret-undeclared` | error | | registry username/password references undeclared secret |
| `ssl-without-host` | error | | `proxy.ssl: true` without `host:` (Let's Encrypt won't work) |
| `empty-web-role` | error | | `servers:` empty or has no hosts in any role |
| `accessory-placement-missing` | error | | accessory has no `host`/`hosts`/`roles` declared |
| `missing-service-name` | error | ✓ | `service:` not set |
| `traefik-legacy-keys` | warning | ✓ | Kamal 1.x `traefik:` block (silently ignored by Kamal 2+) |
| `boot-limit-exceeds-hosts` | warning | | `boot.limit` greater than the number of hosts |
| `kamal-secrets-not-gitignored` | warning | ✓ | `.kamal/secrets` exists but isn't gitignored |
| `secret-in-env-clear` | warning | | `env.clear` value looks like a secret (`*_KEY`/`*_TOKEN`/`*_SECRET`/etc.) |
| `missing-proxy-healthcheck` | warning | | `proxy:` block with no `healthcheck:` (no zero-downtime guarantee) |
| `accessory-image-latest` | warning | | accessory pinned to `:latest` or unpinned |
| `registry-without-explicit-server` | warning | | `registry.server` missing; image silently defaults to Docker Hub |

Run `kamal-lint list-checks` for the same table in your terminal, including the Kamal version range each check applies to.

## Autofix

`--fix` rewrites your config in-place for the safe subset:

- `traefik-legacy-keys` → translates `traefik:` to a `proxy:` block (host, ssl, app_port)
- `missing-service-name` → infers `service:` from the project directory name
- `kamal-secrets-not-gitignored` → appends `.kamal/secrets` to `.gitignore`

```bash
bundle exec kamal-lint --fix
```

> **Heads-up:** autofixes re-serialize your YAML, which means comments and exact formatting are not preserved. Run on a clean working tree so you can review the diff. Anything riskier (e.g. moving env.clear values to env.secret) stays manual on purpose.

## Destination overrides

```bash
bundle exec kamal-lint -d production
```

Loads `config/deploy.yml`, deep-merges `config/deploy.production.yml` on top, then runs the full check suite against the merged config. Lets you catch staging/production-only issues without running `kamal deploy`.

## CI / GitHub Actions

Drop this into `.github/workflows/lint.yml`:

```yaml
name: kamal-lint
on: [push, pull_request]
jobs:
  kamal-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec kamal-lint --format=github
```

The `--format=github` emits GitHub Actions workflow commands so findings show up as inline annotations on the changed file.

A composite Action wrapper is also published in this repo at `action.yml`:

```yaml
- uses: davafons/kamal-lint@v0
  with:
    config-file: config/deploy.yml
    destination: production
    fail-on: warning
```

## Kamal version support

`kamal-lint` reuses your installed Kamal's loader for the parse layer — it auto-tracks whatever Kamal version is in your `Gemfile.lock`. Each check declares a `since:` / `until_version:` range so the registry filters checks to those applicable to your version.

| kamal-lint | supported kamal |
|---|---|
| `0.1.x` | `>= 2.0`, `< 3.0` |

Override detection with `--kamal-version 2.5.0` when needed (e.g. for CI matrix runs).

## Development

```bash
bin/setup     # bundle install
bin/test      # run the test suite
bin/console   # IRB with kamal-lint loaded
```

To lint the gem's own source:

```bash
BUNDLE_ONLY=rubocop bundle exec rubocop
```

## Contributing

Bug reports and pull requests welcome at [github.com/davafons/kamal-lint](https://github.com/davafons/kamal-lint).

## License

MIT. See [MIT-LICENSE](./MIT-LICENSE).
