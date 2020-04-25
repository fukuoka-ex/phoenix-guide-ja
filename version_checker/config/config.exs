import Config

config :version_checker,
  our_repo: "fukuoka-ex/phoenix-guide-ja",
  their_repo: "phoenixframework/phoenix",
  github_token: System.get_env("GITHUB_TOKEN"),
  # 開発中に気軽にissueが作られるとつらいので、デフォルトだとfalseにしている
  post_issue: false,
  guide_files:
    %{
      "1.4" => [
        "guides/introduction/overview.md",
        "guides/introduction/installation.md",
        "guides/introduction/learning.md",
        "guides/introduction/community.md",
        "guides/up_and_running.md",
        "guides/adding_pages.md",
        "guides/routing.md",
        "guides/plug.md",
        "guides/endpoint.md",
        "guides/controllers.md",
        "guides/views.md",
        "guides/templates.md",
        "guides/channels.md",
        "guides/presence.md",
        "guides/ecto.md",
        "guides/contexts.md",
        "guides/phoenix_mix_tasks.md",
        "guides/errors.md",
        "guides/testing/testing.md",
        "guides/testing/testing_schemas.md",
        "guides/testing/testing_controllers.md",
        "guides/testing/testing_channels.md",
        "guides/deployment/deployment.md",
        "guides/deployment/releases.md",
        "guides/deployment/heroku.md"
      ],
      "1.5" => [
        "guides/plug.md",
        "guides/routing.md",
        "guides/introduction/overview.md",
        "guides/introduction/community.md",
        "guides/introduction/up_and_running.md",
        "guides/introduction/installation.md",
        "guides/request_lifecycle.md",
        "guides/views.md",
        "guides/contexts.md",
        "guides/realtime/channels.md",
        "guides/realtime/presence.md",
        "guides/testing/testing_controllers.md",
        "guides/testing/testing.md",
        "guides/testing/testing_contexts.md",
        "guides/testing/testing_channels.md",
        "guides/ecto.md",
        "guides/deployment/releases.md",
        "guides/deployment/heroku.md",
        "guides/deployment/deployment.md",
        "guides/howto/custom_error_pages.md",
        "guides/howto/using_ssl.md",
        "guides/mix_tasks.md",
        "guides/controllers.md",
        "guides/directory_structure.md"
      ]
    }


if "#{Mix.env()}.secret.exs" |> Path.expand(__DIR__) |> File.exists?() do
  import_config "#{Mix.env()}.secret.exs"
end
