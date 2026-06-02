defmodule FrozenClock do
  @moduledoc """
  A minimal, async-safe wrapper around `DateTime.utc_now/0` that lets tests
  freeze and travel time **in the calling process**.

  Replace direct calls to `DateTime.utc_now/0` with `FrozenClock.utc_now/0` in
  production code. In tests, `freeze/0`, `freeze/1`, `travel/1`, and `travel/2`
  pin or shift the clock for the current process only.

  ## Isolation

  All state lives in the process dictionary under a single key, so freezing time
  in one process never affects another. This makes `async: true` tests safe out
  of the box.

  > #### Spawned processes see real time {: .warning}
  >
  > Freezing affects only the calling process. Code that spawns processes
  > (`Task.async/1`, sending to a `GenServer`, Phoenix channels, ...) will see
  > the real system time in those children. If you need cross-process control,
  > use [`klotho`](https://hex.pm/packages/klotho).
  """

  @key :frozen_clock_at

  @doc """
  Returns the current time.

  When the calling process has frozen time, returns the frozen value; otherwise
  delegates to `DateTime.utc_now/0`.

  ## Examples

      iex> FrozenClock.freeze(~U[2026-01-01 00:00:00Z])
      iex> FrozenClock.utc_now()
      ~U[2026-01-01 00:00:00Z]

  """
  @spec utc_now() :: DateTime.t()
  def utc_now do
    case Process.get(@key) do
      nil -> DateTime.utc_now()
      %DateTime{} = frozen -> frozen
    end
  end

  @doc """
  Freezes time for the calling process.

  With no argument, freezes at the current real time. With a `DateTime`, freezes
  at that instant.
  """
  @spec freeze() :: :ok
  @spec freeze(DateTime.t()) :: :ok
  def freeze(at \\ nil)

  def freeze(nil), do: freeze(DateTime.utc_now())

  def freeze(%DateTime{} = at) do
    Process.put(@key, at)
    :ok
  end

  @doc """
  Removes any freeze for the calling process, restoring real time.

  Safe to call when time is not frozen.
  """
  @spec unfreeze() :: :ok
  def unfreeze do
    Process.delete(@key)
    :ok
  end

  @doc """
  Sets the frozen time to `target`.

  If the process is not already frozen, this freezes it at `target`.
  """
  @spec travel(DateTime.t()) :: :ok
  def travel(%DateTime{} = target) do
    Process.put(@key, target)
    :ok
  end

  @doc """
  Shifts the frozen time by `amount` of `unit`.

  Raises if the calling process has not frozen time first.

  ## Examples

      iex> FrozenClock.freeze(~U[2026-01-01 00:00:00Z])
      iex> FrozenClock.travel(1, :hour)
      iex> FrozenClock.utc_now()
      ~U[2026-01-01 01:00:00Z]

  """
  @spec travel(integer(), :day | :hour | :minute | System.time_unit()) :: :ok
  def travel(amount, unit) when is_integer(amount) do
    case Process.get(@key) do
      nil ->
        raise "FrozenClock is not frozen; call FrozenClock.freeze/0 before travel/2"

      %DateTime{} = current ->
        Process.put(@key, DateTime.add(current, amount, unit))
        :ok
    end
  end

  @doc """
  Returns `true` when the calling process has frozen time.
  """
  @spec frozen?() :: boolean()
  def frozen? do
    Process.get(@key) != nil
  end
end
