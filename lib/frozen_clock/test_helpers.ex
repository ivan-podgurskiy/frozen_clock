defmodule FrozenClock.TestHelpers do
  @moduledoc """
  Convenience helpers for using `FrozenClock` in tests.

      import FrozenClock.TestHelpers

      test "expires after 1 hour" do
        freeze_time ~U[2026-01-01 00:00:00Z] do
          token = create_token()
          travel(1, :hour)
          assert expired?(token)
        end
      end
  """

  @doc """
  Freezes time at `datetime` for the duration of the block.

  Time is always unfrozen afterwards, even if the block raises.
  """
  defmacro freeze_time(datetime, do: block) do
    quote do
      FrozenClock.freeze(unquote(datetime))

      try do
        unquote(block)
      after
        FrozenClock.unfreeze()
      end
    end
  end

  @doc """
  Re-export of `FrozenClock.travel/2` so tests only need to import this module.
  """
  defdelegate travel(amount, unit), to: FrozenClock
end
