defmodule Mix.Tasks.VersionChecker.Run do
  use Mix.Task

  def run(_args) do
    Tentacat.start()

    client =
      Tentacat.Client.new(%{access_token: Application.get_env(:version_checker, :github_token)})

    translate_repo = Application.get_env(:version_checker, :translate_repo)
    original_repo = Application.get_env(:version_checker, :original_repo)
    translate_repo_dir = Path.basename(translate_repo)
    original_repo_dir = Path.basename(original_repo)

    {:ok, _} = Git.clone(["https://github.com/#{translate_repo}", "--depth", "1"])
    {:ok, _} = Git.clone("https://github.com/#{original_repo}")

    Application.get_env(:version_checker, :guide_files)
    |> Enum.each(fn guide_file ->
      translate_file = String.replace(guide_file, "guides/", "guides/1.4/")

      # TODO: hashのconfigを生やすまでtitleで仮置き
      translate_hash = get_translate_file_config(translate_repo_dir, translate_file)[:title]
      original_file_latest_hash = get_latest_hash(original_repo_dir, guide_file)

      case String.equivalent?(translate_hash, original_file_latest_hash) do
        true ->
          :ok

        false ->
          post_issue(client, %{
            guide_file: guide_file,
            translate_hash: translate_hash,
            original_file_latest_hash: original_file_latest_hash
          })
      end
    end)
  end

  @doc """
  最新のcommit hashを取得する
  """
  def get_latest_hash(repo_dir, filepath) do
    args =
      ~s(--git-dir #{repo_dir}/.git log -n 1 --pretty=format:"%h" -- #{filepath})
      |> String.split(" ")

    {commit_short_hash, 0} = System.cmd("git", args)

    String.trim(commit_short_hash, ~s("))
  end

  @doc """
  翻訳ファイルの設定を取得する
  """
  def get_translate_file_config(repo_dir, filepath) do
    Path.join([repo_dir, filepath])
    |> File.read!()
    |> extract_yml_config()
  end

  @doc """
  翻訳ファイル文字列から設定部分を抽出する
  """
  def extract_yml_config(file_content) do
    file_content
    |> String.split("---", parts: 3)
    |> Enum.at(1)
    |> String.split("\n")
    |> Enum.reject(fn item -> item == "" end)
    |> Enum.map(fn yml_line_string ->
      [key, val] =
        yml_line_string
        |> String.split(":")
        |> Enum.map(&String.trim/1)

      {String.to_atom(key), val}
    end)
  end

  @doc """
  issueの作成
  """
  def post_issue(client, attrs) do
    run? = Application.get_env(:version_checker, :post_issue, false)

    if run? do
      [owner, repo] = Path.split(Application.get_env(:version_checker, :translate_repo))

      Tentacat.Issues.create(client, owner, repo, %{
        title: issue_title(),
        body: issue_body(attrs)
      })
    else
      :ok
    end
  end

  defp issue_title() do
    "test issue"
  end

  defp issue_body(%{
         guide_file: guide_file,
         translate_hash: translate_hash,
         original_file_latest_hash: original_file_latest_hash
       }) do
    ~s(
      ## 概要
      - 翻訳元リポジトリに修正が加わっています
      - ファイル: #{guide_file}

      ## commit log
      - 翻訳元ファイルの最新commit: https://github.com/phoenixframework/phoenix/blob/#{original_file_latest_hash}/#{guide_file}
      - 翻訳後ファイルのcommit hash: https://github.com/phoenixframework/phoenix/blob/#{translate_hash}/#{guide_file}
      - history: https://github.com/phoenixframework/phoenix/commits/#{original_file_latest_hash}/#{guide_file}
    )
  end
end
