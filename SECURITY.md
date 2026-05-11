# Security Policy

## Supported versions

Only the latest minor version is supported. Security fixes will be released as a patch on the latest minor.

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅        |
| < 0.1   | ❌        |

## Reporting a vulnerability

**Please do not file a public GitHub issue for security problems.**

Report privately via [GitHub Security Advisories](https://github.com/davafons/kamal-lint/security/advisories/new), or by email to <davafons@gmail.com>.

Include:

- a description of the issue and its impact
- a minimal `config/deploy.yml` (or other) reproducer if applicable
- the kamal-lint version, kamal version, and Ruby version
- any suggested fix

### What's in scope

- Code injection or arbitrary command execution via crafted YAML input to kamal-lint
- Path traversal or accidental disclosure of files outside the project tree
- Compromise of the release pipeline (e.g. tag-injection vectors, OIDC misuse in `release.yml`)
- Bugs in autofixes that write outside `config/deploy.yml`, `.kamal/secrets`, or `.gitignore`

### What's out of scope

- False positives or false negatives in lint rules (those are bug reports — use the issue tracker)
- Vulnerabilities in kamal itself (report those to <https://github.com/basecamp/kamal/security>)
- Vulnerabilities in transitive dependencies that are already patched upstream

## Response timeline

I aim to acknowledge reports within 7 days and ship a fix within 30 days. Coordinated disclosure preferred; please give me a chance to release a fix before going public.
