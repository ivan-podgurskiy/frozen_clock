defmodule FrozenClockTest do
  use ExUnit.Case, async: true
  doctest FrozenClock

  describe "utc_now/0 without freeze" do
    test "returns a real DateTime close to the system clock" do
      before = DateTime.utc_now()
      now = FrozenClock.utc_now()
      later = DateTime.utc_now()

      assert %DateTime{} = now
      assert DateTime.compare(now, before) in [:gt, :eq]
      assert DateTime.compare(now, later) in [:lt, :eq]
    end
  end

  describe "stdlib time wrappers without freeze" do
    test "system_time/0 returns a real native system time close to the system clock" do
      before = System.system_time()
      now = FrozenClock.system_time()
      later = System.system_time()

      assert is_integer(now)
      assert now >= before
      assert now <= later
    end

    test "system_time/1 returns a real system time close to the system clock" do
      before = System.system_time(:second)
      now = FrozenClock.system_time(:second)
      later = System.system_time(:second)

      assert is_integer(now)
      assert now >= before
      assert now <= later
    end

    test "date, time, and naive datetime wrappers return real values" do
      assert %Date{} = FrozenClock.utc_today()
      assert %Time{} = FrozenClock.utc_time()
      assert %NaiveDateTime{} = FrozenClock.naive_utc_now()
    end
  end

  describe "freeze/0" do
    test "returns the same value on repeated utc_now/0 calls" do
      assert :ok = FrozenClock.freeze()
      first = FrozenClock.utc_now()
      Process.sleep(5)
      second = FrozenClock.utc_now()

      assert first == second
    end
  end

  describe "freeze/1" do
    test "pins utc_now/0 to the given DateTime" do
      at = ~U[2026-01-01 00:00:00Z]
      assert :ok = FrozenClock.freeze(at)

      assert FrozenClock.utc_now() == at
    end

    test "pins derived stdlib time wrappers to the given DateTime" do
      at = ~U[2026-01-01 12:34:56.789123Z]
      assert :ok = FrozenClock.freeze(at)

      assert FrozenClock.system_time() == 1_767_270_896_789_123_000
      assert FrozenClock.system_time(:microsecond) == 1_767_270_896_789_123
      assert FrozenClock.utc_today() == ~D[2026-01-01]
      assert FrozenClock.utc_time() == ~T[12:34:56.789123]
      assert FrozenClock.naive_utc_now() == ~N[2026-01-01 12:34:56.789123]
    end

    test "derives UTC wrappers from the frozen instant, not the DateTime zone" do
      at = %DateTime{
        calendar: Calendar.ISO,
        year: 2026,
        month: 1,
        day: 2,
        hour: 1,
        minute: 30,
        second: 0,
        microsecond: {123_456, 6},
        time_zone: "Custom/Plus02",
        zone_abbr: "+02",
        utc_offset: 7200,
        std_offset: 0
      }

      assert :ok = FrozenClock.freeze(at)

      assert FrozenClock.utc_today() == ~D[2026-01-01]
      assert FrozenClock.utc_time() == ~T[23:30:00.123456]
      assert FrozenClock.naive_utc_now() == ~N[2026-01-01 23:30:00.123456]
    end
  end

  describe "unfreeze/0" do
    test "restores real time" do
      FrozenClock.freeze(~U[2000-01-01 00:00:00Z])
      assert :ok = FrozenClock.unfreeze()

      assert DateTime.diff(DateTime.utc_now(), FrozenClock.utc_now(), :second) |> abs() <= 2
    end

    test "is safe to call when not frozen" do
      assert :ok = FrozenClock.unfreeze()
    end
  end

  describe "frozen?/0" do
    test "reflects the freeze state" do
      refute FrozenClock.frozen?()
      FrozenClock.freeze()
      assert FrozenClock.frozen?()
      FrozenClock.unfreeze()
      refute FrozenClock.frozen?()
    end
  end

  describe "travel/1" do
    test "moves frozen time to the given DateTime" do
      FrozenClock.freeze(~U[2026-01-01 00:00:00Z])
      assert :ok = FrozenClock.travel(~U[2026-06-01 12:00:00Z])

      assert FrozenClock.utc_now() == ~U[2026-06-01 12:00:00Z]
    end

    test "freezes at the target when not already frozen" do
      refute FrozenClock.frozen?()
      assert :ok = FrozenClock.travel(~U[2026-06-01 12:00:00Z])

      assert FrozenClock.frozen?()
      assert FrozenClock.utc_now() == ~U[2026-06-01 12:00:00Z]
    end
  end

  describe "travel/2" do
    test "shifts frozen time forward by the given amount" do
      FrozenClock.freeze(~U[2026-01-01 00:00:00Z])
      assert :ok = FrozenClock.travel(1, :hour)

      assert FrozenClock.utc_now() == ~U[2026-01-01 01:00:00Z]
    end

    test "shifts frozen time backward with a negative amount" do
      FrozenClock.freeze(~U[2026-01-01 00:00:00Z])
      assert :ok = FrozenClock.travel(-30, :minute)

      assert FrozenClock.utc_now() == ~U[2025-12-31 23:30:00Z]
    end

    test "raises with a clear message when not frozen" do
      refute FrozenClock.frozen?()

      assert_raise RuntimeError, ~r/not frozen/i, fn ->
        FrozenClock.travel(1, :hour)
      end
    end
  end
end
