# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-01

### Added

- `FrozenClock` core API: `utc_now/0`, `freeze/0`, `freeze/1`, `unfreeze/0`,
  `travel/1`, `travel/2`, and `frozen?/0`. State is kept in the process
  dictionary, so freezing is isolated per process and `async: true` tests are
  safe.
- `FrozenClock.TestHelpers` with the `freeze_time/2` macro (guaranteed unfreeze,
  even on raise) and a `travel/2` re-export.
- Unit, property, and isolation tests, including the documented behavior that
  spawned processes see real time.

[0.1.0]: https://github.com/ivan-podgurskiy/frozen_clock/releases/tag/v0.1.0
