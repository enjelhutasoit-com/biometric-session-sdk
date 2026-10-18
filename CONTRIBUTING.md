# Contributing

## Workflow

1. Fork and clone.
2. Create a branch: `git switch -c <type>/<short-name>`
3. Write a failing test first.
4. Write the minimum production code to make it pass.
5. Run `swift test`.
6. Commit with Conventional Commits.
7. Open a pull request using the template.

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
