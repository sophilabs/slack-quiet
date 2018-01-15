defmodule SlackSilenceWeb.Router do
  use SlackSilenceWeb, :router

  scope "/", SlackSilenceWeb do
    get "/", SlashController, :health_check

    post "/", SlashController, :slash_command
  end
end
