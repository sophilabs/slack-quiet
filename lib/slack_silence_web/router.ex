defmodule SlackQuietWeb.Router do
  use SlackQuietWeb, :router

  scope "/", SlackQuietWeb do
    get("/", SlashController, :health_check)

    post("/", SlashController, :slash_command)
  end
end
