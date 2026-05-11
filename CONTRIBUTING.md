# Contributing to kamal-lint

Thanks for your interest in improving kamal-lint.

## Reporting bugs

Open an issue at <https://github.com/davafons/kamal-lint/issues> with:
- the `kamal-lint --version` output
- the `kamal version` output
- the smallest `config/deploy.yml` snippet that reproduces the problem
- what you expected to happen vs. what you saw

## Proposing new checks

Open an issue describing the footgun the check would catch, with a tiny YAML example. The bar for a check is:
- it catches a real, common Kamal misconfiguration
- the misconfiguration is *not* already caught by `kamal config` at parse time
- the check produces no false positives on a typical valid config

## Submitting a pull request

```bash
bin/setup     # bundle install
bin/test      # run the test suite
BUNDLE_ONLY=rubocop bundle exec rubocop --parallel
```

PRs must:
- pass `bin/test` and rubocop
- add a test for any new check or autofix
- update `CHANGELOG.md` under `## [Unreleased]`
- not increase scope beyond what the issue describes

### Adding a check

1. Create `lib/kamal/lint/checks/<your_check>.rb` subclassing `Kamal::Lint::Check`. Declare `id`, `severity`, `since`, optional `until_version`, optional `autofixable true`, and a `title`. Implement `#call` returning an array of `Finding`s.
2. Register it at the bottom of the file: `Lint.registry.register(YourCheck)`
3. Require it from `lib/kamal/lint.rb`
4. Add `test/checks/<your_check>_test.rb` covering positive case, negative case, and at least one edge.
5. Update the check table in `README.md` and the `[Unreleased]` section in `CHANGELOG.md`.

### Adding an autofix

Set `autofixable true` on the check class and implement `apply_fix(ctx)` returning `true` on success / `false` on no-op or failure. Pass `autofix: method(:apply_fix)` when constructing the `Finding`.

Autofixes must be safe under any execution order (other autofixes may run on the same file before or after yours). Prefer parse-and-redump (`YAML.safe_load` then `YAML.dump`) over textual rewrites.

## Code style

Standard `rubocop-rails-omakase`. No special exceptions.

## Releasing

Maintainers only — push a `vX.Y.Z` git tag and the release workflow handles the rest.
