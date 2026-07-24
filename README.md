# FrozenClock

[![CI](https://github.com/ivan-podgurskiy/frozen_clock/actions/workflows/ci.yml/badge.svg)](https://github.com/ivan-podgurskiy/frozen_clock/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Minimal, async-safe wrappers around common UTC date/time calls that let tests
freeze and travel time **in the calling process** — no behaviours, no mocks, no
struct threaded through your function signatures.

Replace direct calls like `DateTime.utc_now/0`, `System.system_time/1`, and
`Date.utc_today/0` with the matching `FrozenClock` wrapper in production code,
and freeze time in tests. State lives in the process dictionary, so async tests
are isolated out of the box.

## Installation

```elixir
def deps do
  [
    {:frozen_clock, "~> 0.2.0"}
  ]
end
```

## Usage

In production code, call `FrozenClock.utc_now/0` where you would have called
`DateTime.utc_now/0`:

```elixir
def expired?(token) do
  DateTime.compare(FrozenClock.utc_now(), token.expires_at) == :gt
end
```

In tests, freeze and travel time:

```elixir
import FrozenClock.TestHelpers

test "expires after 1 hour" do
  freeze_time ~U[2026-01-01 00:00:00Z] do
    token = create_token()
    travel(1, :hour)
    assert expired?(token)
  end
end
```

`freeze_time/2` guarantees the clock is unfrozen after the block, even if it
raises.

### API

```elixir
FrozenClock.utc_now()                       # frozen value or real DateTime
FrozenClock.system_time()                   # frozen or real System.system_time/0
FrozenClock.system_time(:second)            # frozen or real System.system_time/1
FrozenClock.utc_today()                     # frozen or real Date.utc_today/0
FrozenClock.utc_time()                      # frozen or real Time.utc_now/0
FrozenClock.naive_utc_now()                 # frozen or real NaiveDateTime.utc_now/0
FrozenClock.freeze()                         # freeze at the current real time
FrozenClock.freeze(~U[2026-01-01 00:00:00Z]) # freeze at a specific instant
FrozenClock.travel(~U[2026-06-01 12:00:00Z]) # jump to an instant (freezes if needed)
FrozenClock.travel(1, :hour)                 # shift by a duration (raises if not frozen)
FrozenClock.frozen?()                        # => true | false
FrozenClock.unfreeze()                       # restore real time (safe if not frozen)
```

## Isolation: spawned processes see real time

FrozenClock freezes time in the **calling process only**. Code under test that
spawns processes — `Task.async/1`, sending to a `GenServer`, Phoenix channels —
will see the **real** system time in those children.

For the common case (testing a pure function or a single module) this is exactly
what you want and keeps async tests safe. If you need cross-process freeze, use
[`klotho`](https://hex.pm/packages/klotho).

## Comparison

| Need | Use |
|---|---|
| Freeze UTC date/time wrappers in a test (same process) | **FrozenClock** |
| Minimal API, no magic, no extra arguments in production code | **FrozenClock** |
| Explicit DI: a clock struct + protocol passed as a function argument | [`clock`](https://hex.pm/packages/clock) |
| Control `Process.send_after/3`, `:timer`, scheduled work | [`klotho`](https://hex.pm/packages/klotho) |
| Cross-process freeze (`Task`, `GenServer`) | [`klotho`](https://hex.pm/packages/klotho) |
| A mock-first workflow with an explicit `Mock` namespace | [`klotho`](https://hex.pm/packages/klotho) |

FrozenClock isn't "better than klotho" or "better than clock" — it solves a
different problem: freezing time via the process dictionary without changing your
production function signatures.

## License

MIT. See [LICENSE](LICENSE).
