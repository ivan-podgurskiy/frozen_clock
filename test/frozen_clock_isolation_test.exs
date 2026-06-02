defmodule FrozenClockIsolationTest do
  use ExUnit.Case, async: true

  test "freezes are isolated per process" do
    a = ~U[2001-01-01 00:00:00Z]
    b = ~U[2002-02-02 00:00:00Z]

    task_a =
      Task.async(fn ->
        FrozenClock.freeze(a)
        Process.sleep(10)
        FrozenClock.utc_now()
      end)

    task_b =
      Task.async(fn ->
        FrozenClock.freeze(b)
        Process.sleep(10)
        FrozenClock.utc_now()
      end)

    assert Task.await(task_a) == a
    assert Task.await(task_b) == b
    refute FrozenClock.frozen?()
  end

  test "a freeze in the parent does not leak into a spawned process (documented behavior)" do
    FrozenClock.freeze(~U[2000-01-01 00:00:00Z])

    spawned_now = Task.async(fn -> FrozenClock.utc_now() end) |> Task.await()

    refute spawned_now == ~U[2000-01-01 00:00:00Z]
    assert abs(DateTime.diff(DateTime.utc_now(), spawned_now, :second)) <= 2
  end
end
