<h1 align="center">kamal-lint</h1>

<p align="center">
  <a href="https://rubygems.org/gems/kamal-lint"><img src="https://img.shields.io/gem/v/kamal-lint" alt="Gem Version"></a>
  <a href="https://github.com/davafons/kamal-lint/actions/workflows/ci.yml"><img src="https://github.com/davafons/kamal-lint/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/davafons/kamal-lint/blob/main/MIT-LICENSE"><img src="https://img.shields.io/github/license/davafons/kamal-lint" alt="License"></a>
  <a href="https://rubygems.org/gems/kamal-lint"><img src="https://img.shields.io/gem/dt/kamal-lint" alt="Downloads"></a>
</p>

Static linter for [Kamal](https://kamal-deploy.org) `config/deploy.yml`. Catches missing secrets, role/registry mismatches, and proxy footguns that Kamal silently allows.

<p align="center">
  <img src="docs/preview.svg" alt="kamal-lint output sample" width="760">
</p>

## Install

```ruby
# Gemfile
group :development, :test do
  gem "kamal-lint", require: false
end
```

```bash
bundle exec kamal-lint
```

## Usage

**Default: lint base + every destination override at once.**

```bash
bundle exec kamal-lint
```

Auto-discovers `config/deploy.*.yml` files next to your base `config/deploy.yml` and lints each (base alone, then each destination merged onto base). Output groups findings by destination — bugs that live in a `deploy.production.yml` override show up *only* under `[production]`:

```
[base]       config/deploy.yml
  ✓ No issues found.

[production] config/deploy.production.yml
  ⚠ warning  ...
      `traefik:` block is Kamal 1.x legacy ...

[staging]    config/deploy.staging.yml
  ✓ No issues found.

Summary: 1 warning across 3 configs
```

Exits `1` if any findings are at or above `--fail-on` (default: `warning`), `0` otherwise.

**Narrow to a single destination:**

```bash
bundle exec kamal-lint -d production
```

Useful in CI matrix jobs or when debugging one destination. Skips auto-discovery; only lints `deploy.yml + deploy.production.yml`.

**Other knobs:**

```bash
bundle exec kamal-lint -c infra/deploy.yml      # non-default config path
bundle exec kamal-lint list-checks              # show every registered check
bundle exec kamal-lint --format=json            # machine-readable output
bundle exec kamal-lint --include-kamal-errors   # also surface Kamal's loader errors
```

**In CI:**

```yaml
- uses: davafons/kamal-lint@v0.1.0
  with:
    fail-on: warning
```

`--format=github` is set automatically so findings show as inline annotations in the PR view. By default the action lints all destinations; set `destination: production` to narrow.

## Checks

| ID | Severity | What it catches |
|---|---|---|
| `secret-not-declared` | error | `env.secret` (top-level or per-accessory) references a key that isn't declared in `.kamal/secrets`. Kamal would fail at deploy time. |
| `accessory-role-undefined` | error | An accessory's `roles:` lists a role name that isn't defined under `servers:`. The accessory won't deploy to anything. |
| `role-hosts-empty` | error | A role under `servers:` has no hosts. Deploys to that role silently no-op. |
| `image-registry-mismatch` | error | `image:` doesn't include the prefix of `registry.server`. Kamal would push/pull from the wrong registry. (Docker Hub is exempt — unprefixed images resolve there automatically.) |
| `builder-registry-secret-undeclared` | error | `registry.username` or `registry.password` references a secret name that isn't in `.kamal/secrets`. |
| `ssl-without-host` | error | `proxy.ssl: true` without a `host:` (or `hosts:`). Let's Encrypt provisioning has nothing to issue against. |
| `empty-web-role` | error | `servers:` is empty or every role has no hosts. Nothing would be deployed. |
| `accessory-placement-missing` | error | An accessory has none of `host`, `hosts`, or `roles` declared, so Kamal has no idea where to put it. |
| `missing-service-name` | error | `service:` is not set. Kamal can't name the container. |
| `traefik-legacy-keys` | warning | A `traefik:` block is still present. Kamal 2+ uses `proxy:` and silently ignores the old block. |
| `boot-limit-exceeds-hosts` | warning | `boot.limit` is greater than the total number of hosts, so the rolling-deploy limit has no effect. |
| `kamal-secrets-not-gitignored` | warning | `.kamal/secrets` exists in the repo but isn't matched by `.gitignore`. Real credentials are one `git add .` away from a commit. |
| `secret-in-env-clear` | warning | A key in `env.clear` looks like a secret (`*_KEY`, `*_TOKEN`, `*_SECRET`, `*PASSWORD*`). Move it to `env.secret` + `.kamal/secrets`. |
| `missing-proxy-healthcheck` | warning | The `proxy:` block has no `healthcheck:`. Kamal-proxy can't verify a new release before cutting traffic — zero-downtime deploys may fail. |
| `accessory-image-latest` | warning | An accessory's `image:` is pinned to `:latest` (or has no tag). Updates can change unexpectedly between deploys. |
| `registry-without-explicit-server` | warning | `registry` is set but `registry.server` isn't. Kamal silently defaults to Docker Hub. |
| `kamal-parse-error` | error | *Opt-in.* Surfaces errors from Kamal's own loader. Enable with `--include-kamal-errors`. Useful in CI as a complement to `kamal config`. |

Reasoning behind each finding is also in the message text — paste a finding into search and you'll usually land on the relevant Kamal doc.

## Flags

```
-c, --config-file PATH      config/deploy.yml
-d, --destination NAME      lint deploy.<name>.yml merged onto base
-f, --format FORMAT         human | json | github
    --fail-on LEVEL         error | warning | info
    --kamal-version VER     override detected Kamal version
    --include-kamal-errors  also surface Kamal's loader errors
```

Exit codes: `0` clean · `1` findings at/above `--fail-on` · `2` config missing.

## Kamal versions

| kamal-lint | kamal | tested against |
|---|---|---|
| `0.1.x` | `>= 2.0`, `< 3.0` | latest 2.x |

`kamal-lint` reuses your installed Kamal's loader, so it auto-tracks whatever's in your `Gemfile.lock`. Older 2.x versions likely work but aren't covered by CI — if you hit a bug on an older Kamal, please [open an issue](https://github.com/davafons/kamal-lint/issues). Override the detected version with `--kamal-version 2.5.0` for matrix runs.

## Development

```bash
bin/setup     # install
bin/test      # run tests
bin/console   # IRB with kamal-lint loaded
```

Contributions: [CONTRIBUTING.md](./CONTRIBUTING.md) · Security: [SECURITY.md](./SECURITY.md) · License: [MIT](./MIT-LICENSE).
