# Security Policy

## Scope and limits

See `Docs/ThreatModel.md` for attackers, mitigations, and open questions.
This library runs on the client.
A jailbroken device, a hooked process, or a modified binary can bypass its checks.
It is not a security boundary.
Server-side authorization is required for anything sensitive.

## Supported versions

Only the latest release receives fixes.
Current: `0.4.x`.

## Reporting a vulnerability

Do not open a public issue.
Use GitHub private vulnerability reporting:
the "Report a vulnerability" button on the repository Security tab.

Include: affected commit or version, steps to reproduce,
whether the result was seen on SIMULATOR or DEVICE, and iOS version.

No response-time guarantee is made by this project.
