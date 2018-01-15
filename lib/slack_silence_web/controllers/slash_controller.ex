defmodule SlackSilenceWeb.SlashController do
  @moduledoc """
  The slash command controller.
  """

  use SlackSilenceWeb, :controller
  import SlackSilence.LastUsageRegistry

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

  defp do_slash_command(conn, %{"user_id" => user_id, "response_url" => response_url}, true) do
    send_delayed_response(response_url)

    put_last_usage(user_id)

    send_resp(conn, 200, "")
  end

  # Sends the delayed response back to Slack.
  defp send_delayed_response(response_url) do
    response = %{
      response_type: "in_channel",
      username: "Silence Bot",
      text: "<@here> Someone is asking for silence. (TEST)",
    }

    headers = ["Content-Type": "application/json"]

    HTTPoison.post!(response_url, Poison.encode!(response), headers)
  end

  defp do_slash_command(conn, %{"user_id" => user_id}, _) do
    next_usage_message =
      user_id
      |> get_seconds_until_next_usage()
      |> get_next_usage_string()

    response = %{
      response_type: "ephemeral",
      text: "You just asked for silence. #{next_usage_message}",
    }

    json(conn, response)
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