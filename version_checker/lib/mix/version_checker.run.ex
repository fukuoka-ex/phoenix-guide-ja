defmodule Mix.Tasks.VersionChecker.Run do
  use Mix.Task

  require Logger

  def run(_args) do
    Tentacat.start()

    client =
      Tentacat.Client.new(%{access_token: Application.get_env(:version_checker, :github_token)})

    our_repo = Application.get_env(:version_checker, :our_repo)
    their_repo = Application.get_env(:version_checker, :their_repo)
    our_repo_dir = Path.basename(our_repo)
    their_repo_dir = Path.basename(their_repo)

    Logger.debug("clone https://github.com/#{our_repo}.")
    Logger.debug("clone https://github.com/#{their_repo}.")

    {:ok, _} = Git.clone(["https://github.com/#{our_repo}", "--depth", "1"])
    {:ok, _} = Git.clone("https://github.com/#{their_repo}")

    Application.get_env(:version_checker, :guide_files)
    |> Enum.each(fn {version, guide_files} ->
      Enum.each(guide_files, fn guide_file ->
        our_file = String.replace(guide_file, "guides/", "guides/#{version}/")

        our_file_hash = get_our_file_config(our_repo_dir, our_file)[:hash]
        their_file_latest_hash = get_latest_hash(their_repo_dir, version, guide_file)

        # 翻訳ファイルのcommit hashがlong hashの場合でも動作するように、完全一致ではなく先頭の部分一致で判定している
        "^#{their_file_latest_hash}"
        |> Regex.compile!()
        |> Regex.match?(our_file_hash)
        |> case do
          true ->
            :ok

          false ->
            Logger.debug("Hash does not match: #{our_file}")
            Logger.debug("our file hash: #{our_file_hash}")
            Logger.debug("their file hash: #{their_file_latest_hash}")

            post_issue(client, %{
              guide_file: guide_file,
              our_file_hash: our_file_hash,
              their_file_latest_hash: their_file_latest_hash
            })
        end
      end)
    end)
  end

  @doc """
  最新のcommit hashを取得する
  """
  def get_latest_hash(repo_dir, version, filepath) do
    args =
      ~s(--git-dir #{repo_dir}/.git log remotes/origin/v#{version} -n 1 --pretty=format:"%h" -- #{
        filepath
      })
      |> String.split(" ")

    {commit_short_hash, 0} = System.cmd("git", args)

    String.trim(commit_short_hash, ~s("))
  end

  @doc """
  翻訳ファイルの設定を取得する
  """
  def get_our_file_config(repo_dir, filepath) do
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

  実行可能な設定 かつ 同タイトルのissueが存在しない場合のみissueを作成する

  """
  def post_issue(client, attrs) do
    run? = Application.get_env(:version_checker, :post_issue, false)

    [owner, repo] = Path.split(Application.get_env(:version_checker, :our_repo))
    title = issue_title(attrs)

    if run? and !issue_exists?(owner, repo, title) do
      Tentacat.Issues.create(client, owner, repo, %{
        title: issue_title(attrs),
        body: issue_body(attrs)
      })
    else
      :ok
    end
  end

  defp issue_exists?(owner, repo, title) do
    {200, %{"items" => items}, _} =
      Tentacat.Search.issues(%{q: "repo:#{owner}/#{repo} #{title} in:title"})

    Enum.count(items) > 0
  end

  defp issue_title(%{guide_file: guide_file}) do
    "#{guide_file} の翻訳"
  end

  defp issue_body(%{
         guide_file: guide_file,
         our_file_hash: our_file_hash,
         their_file_latest_hash: their_file_latest_hash
       }) do
    """
      ## 概要
      - 翻訳元リポジトリに修正が加わっています
      - ファイル: #{guide_file}

      ## commit log
      - 翻訳元ファイルの最新commit: https://github.com/phoenixframework/phoenix/blob/#{
      their_file_latest_hash
    }/#{guide_file}
      - 翻訳後ファイルのcommit hash: https://github.com/phoenixframework/phoenix/blob/#{
      our_file_hash
    }/#{guide_file}
      - history: https://github.com/phoenixframework/phoenix/commits/#{their_file_latest_hash}/#{
      guide_file
    }
    """
  end
end
