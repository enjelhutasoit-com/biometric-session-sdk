# Contributing

## Workflow

1. Fork and clone.
2. Create a branch: `git switch -c <type>/<short-name>`
3. Write a failing test first.
4. Write the minimum production code to make it pass.
5. Run `./Scripts/lint.sh`.
6. Run `./Scripts/check-concurrency.sh`. A new `@unchecked Sendable` or similar needs a written reason in `Docs/ConcurrencyAudit.md` and an allowlist entry.
7. Run `./Scripts/check-docs.sh`. Doc comments (`///`) must not mention internal commit numbers. A new module needs its own DocC landing page.
8. Run `./Scripts/docbuild.sh` when you change public documentation.
9. Run `./Scripts/check-public-api.sh`. If you changed a public declaration on purpose, run it with `--update`, read the diff, and describe the type in `Docs/PublicAPI.md`. Removing or changing a public declaration needs a major version.
10. Run `./Scripts/check-errors-doc.sh`. A new `BiometricSessionError.Code` needs a`## caseName` heading in `Docs/Errors.md`.
12. Run `swift test`.
12. Commit with Conventional Commits.
13. Open a pull request using the template.

## Formatting

Style is enforced by `swift format` from the Swift toolchain.
Config: `.swift-format`.
Lint (read-only): `./Scripts/lint.sh`
Auto-fix (review the diff before committing):
`swift format format --in-place --recursive Package.swift Sources Tests`

## Commit messages

Format: `<type>(<scope>): <description>`

Types used here: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
Breaking change: add `!` after type/scope, or a `BREAKING CHANGE:` footer.

## Rules

- Zero third-party dependencies.
- `BiometricSessionCore` must not import `LocalAuthentication` or `Security`.
- Types are `internal` by default.
- Every `public` declaration needs a one-line justification in the PR.
- Types crossing concurrency boundaries must be `Sendable`.
- No real sleeping in tests. Inject a clock.
- Unit tests use Swift Testing. XCTest only for `measure` tests.

## Tests

Mark each test as one of:

- `SIMULATOR`: runs on iOS Simulator or macOS host.
- `DEVICE`: needs a physical device with biometrics.
- If behavior differs between simulator and device and you do not know how,
  write `UNKNOWN` and say how to verify.

## Facts

Do not invent Apple API names, availability, or behavior.
If unsure, write `UNKNOWN: <what>. Verify by: <Apple doc or test>.`
