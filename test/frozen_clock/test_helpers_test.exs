defmodule FrozenClock.TestHelpersTest do
  use ExUnit.Case, async: true
  import FrozenClock.TestHelpers

  test "freeze_time/2 freezes for the block and unfreezes afterwards" do
    result =
      freeze_time ~U[2026-01-01 00:00:00Z] do
        start = FrozenClock.utc_now()
        travel(1, :hour)
        {start, FrozenClock.utc_now()}
      end

    assert result == {~U[2026-01-01 00:00:00Z], ~U[2026-01-01 01:00:00Z]}
    refute FrozenClock.frozen?()
  end

  test "freeze_time/2 unfreezes even when the block raises" do
    assert_raise RuntimeError, "boom", fn ->
      freeze_time ~U[2026-01-01 00:00:00Z] do
        raise "boom"
      end
    end

    refute FrozenClock.frozen?()
  end
end
