defmodule FrozenClockTest do
  use ExUnit.Case
  doctest FrozenClock

  test "example/1 doubles integers" do
    assert FrozenClock.example(3) == 6
  end
end
