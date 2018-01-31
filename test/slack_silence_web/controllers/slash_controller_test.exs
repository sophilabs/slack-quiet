defmodule SlackSilenceWeb.SlashControllerTest do
  use SlackSilenceWeb.ConnCase, async: true

  @slack_payload %{
    token: "gIkuvaNzQIHg97ATvDxqgjtO",
    team_id: "T0001",
    team_domain: "example",
    enterprise_id: "E0001",
    enterprise_name: "Globular%20Construct%20Inc",
    channel_id: "C2147483705",
    channel_name: "test",
    user_id: "U2147483697",
    user_name: "Steve",
    command: "/weather",
    text: "94070",
    response_url: "https://hooks.slack.com/commands/1234/5678",
    trigger_id: "13345224609.738474920.8088930838d88f008e0",
  }

  describe "health_check/2" do
    test "always responds with status 200", %{conn: conn} do
      conn = get conn, "/"

      response(conn, 200)
    end
  end

  describe "slash_command/2" do
    test "always responds with status 200", %{conn: conn} do
      conn = post conn, "/", @slack_payload

      response(conn, 200)
    end
  end
end