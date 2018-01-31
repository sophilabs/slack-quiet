defmodule SlackQuiet.LastUsageRegistry do
  @moduledoc """
  We don't want to allow users to spam `/quiet` in Slack, so we throttle them.

  We maintain an agent with information about the last usage of the command
  for every user and we check if it has passed enough seconds since the last time.
  """

  use Agent

  @typedoc "A string representing the user_id of a user."
  @type user_id :: String.t()

  # Seconds to throttle for.
  @throttle 30

  def start_link(_), do: Agent.start_link(&Map.new/0, name: __MODULE__)

  @doc """
  Looks up the user's last usage of the command.

  Returns a `%NaiveDateTime{}` if the user has used the command before.
  `nil` otherwise.

  ## Examples

      iex> lookup_last_usage("user123")
      ~N[2018-01-15 18:11:43.678769]

      iex> lookup_last_usage("user456")
      nil

  """
  @spec lookup_last_usage(user_id) :: NaiveDateTime.t() | nil
  def lookup_last_usage(user_id), do: Agent.get(__MODULE__, &Map.get(&1, user_id))

  @doc """
  Puts `NaiveDateTime.utc_now()` as the user's last usage of the command.

  ## Examples

      iex> put_last_usage("user123")
      :ok

  """
  @spec put_last_usage(user_id, NaiveDateTime.t()) :: :ok
  def put_last_usage(user_id, naive_datetime \\ NaiveDateTime.utc_now()) do
    Agent.update(__MODULE__, &Map.put(&1, user_id, naive_datetime))
  end

  @doc """
  Removes all entries in the registry.

  ## Examples

      iex> flush()
      :ok

  """
  @spec flush :: :ok
  def flush, do: Agent.update(__MODULE__, fn _ -> %{} end)

  @doc """
  Checks if the user is allowed to use the command right now.

  ## Examples

      iex> can_use_command?("user123")
      true

      iex> can_use_command?("user456")
      false

  """
  @spec can_use_command?(user_id) :: boolean
  def can_use_command?(user_id) do
    user_id
    |> lookup_last_usage()
    |> do_can_use_command?()
  end

  defp do_can_use_command?(nil), do: true

  defp do_can_use_command?(last_usage),
    do: NaiveDateTime.diff(NaiveDateTime.utc_now(), last_usage) > @throttle

  @doc """
  Returns the seconds left until the user is allowed
  to use the command again.

  ## Examples

      iex> get_seconds_until_next_usage("user123")
      23

      iex> get_seconds_until_next_usage("user456")
      0

  """
  @spec get_seconds_until_next_usage(user_id) :: non_neg_integer
  def get_seconds_until_next_usage(user_id) do
    user_id
    |> lookup_last_usage()
    |> do_get_seconds_until_next_usage()
  end

  defp do_get_seconds_until_next_usage(nil), do: 0

  defp do_get_seconds_until_next_usage(last_usage) do
    case NaiveDateTime.diff(NaiveDateTime.utc_now(), last_usage) do
      difference when difference < @throttle -> @throttle - difference
      _ -> 0
    end
  end
end
