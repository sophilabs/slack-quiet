defmodule SlackQuietWeb.SlashController do
  @moduledoc """
  The slash command controller.
  """

  use SlackQuietWeb, :controller
  import SlackQuiet.LastUsageRegistry

  @valid_locations ~w(hq brooklyn)

  @locations_names %{"hq" => "HQ", "brooklyn" => "Brooklyn"}

  @command_doc """
  *usage:* `/quiet location floor`

  _Asks for silence in the specified location and floor._

  Examples:

  `/quiet HQ 1`
  `/quiet Brooklyn 2`
  """

  # Slack periodically checks the health of this command.
  def health_check(conn, _params), do: send_resp(conn, 200, "")

  @doc """
  The controller action for the slash command.

  We have to use a delayed response to maintain anonymity.

  If we were to respond back directly, the message the user sent
  to trigger the command will be publicly displayed.
  """
  def slash_command(conn, %{"user_id" => user_id} = params) do
    do_slash_command(conn, params, can_use_command?(user_id))
  end

  defp do_slash_command(
         conn,
         %{"user_id" => user_id, "text" => text, "response_url" => response_url},
         true
       ) do
    args = parse_args(text)

    if valid_args?(args) do
      send_delayed_response(response_url, args)

      put_last_usage(user_id)

      send_resp(conn, 200, "")
    else
      response = %{response_type: "ephemeral", text: @command_doc}

      json(conn, response)
    end
  end

  defp do_slash_command(conn, %{"user_id" => user_id}, _) do
    next_usage_message =
      user_id
      |> get_seconds_until_next_usage()
      |> get_next_usage_string()

    response = %{
      response_type: "ephemeral",
      text: "You just asked for silence. #{next_usage_message}"
    }

    json(conn, response)
  end

  defp parse_args(text) do
    text
    |> String.downcase()
    |> String.trim()
    |> String.split()
  end

  defp valid_args?(args) do
    with 2 <- length(args),
         [location | [floor]] = args,
         true <- location in @valid_locations,
         {_, ""} <- Integer.parse(floor) do
      true
    else
      _ -> false
    end
  end

  # Sends the delayed response back to Slack.
  defp send_delayed_response(response_url, [location | [floor]]) do
    response = %{
      response_type: "in_channel",
      text:
        "<!here> Someone is asking for silence in #{@locations_names[location]}. Floor: #{floor}."
    }

    headers = ["Content-Type": "application/json"]

    HTTPoison.post!(response_url, Poison.encode!(response), headers)
  end

  defp get_next_usage_string(seconds) do
    seconds_string =
      case seconds do
        1 -> "second"
        _ -> "seconds"
      end

    "You can use this command again in #{seconds} #{seconds_string}."
  end
end
