defmodule FrozenClockPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "travel/2 shifts frozen time by exactly the requested duration" do
    check all(
            base <- integer(0..4_102_444_800),
            shift <- integer(-1_000_000..1_000_000),
            max_runs: 200
          ) do
      dt = DateTime.from_unix!(base)
      FrozenClock.freeze(dt)
      FrozenClock.travel(shift, :second)

      assert FrozenClock.utc_now() == DateTime.add(dt, shift, :second)

      FrozenClock.unfreeze()
    end
  end

  property "freeze/1 pins utc_now/0 to the given instant" do
    check all(base <- integer(0..4_102_444_800), max_runs: 200) do
      dt = DateTime.from_unix!(base)
      FrozenClock.freeze(dt)

      assert FrozenClock.utc_now() == dt

      FrozenClock.unfreeze()
    end
  end
end
