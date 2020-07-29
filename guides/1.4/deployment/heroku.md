---
layout: 1.4/layout
version: 1.4
group: deployment
title: Herokuへのデプロイ
nav_order: 3
hash: ca2d5c412ad17743bd36b51f8aabc9b569ca1be7
---
# Herokuへのデプロイ

## 必要な作業

このガイドに必要なのは、動作するPhoenixアプリケーションだけです。デプロイ用の簡単なアプリケーションが必要な方は、[起動ガイド](https://hexdocs.pm/phoenix/up_and_running.html)にしたがってください。

## ゴール

このガイドの主な目的は、Heroku上でPhoenixアプリケーションを実行することです。

## 制限事項

Herokuは素晴らしいプラットフォームであり、Elixirはその上で十分なパフォーマンスを発揮します。しかし、ElixirやPhoenixが提供する高度な機能を活用することを計画している場合は、次のような制限にぶつかる可能性があります。

- コネクションに制限があります
  - Herokuは[同時コネクション数の制限](https://devcenter.heroku.com/articles/http-routing#request-concurrency)と[各コネクションの持続時間](https://devcenter.heroku.com/articles/limits#http-timeouts)があります。Elixirは多くの同時接続や持続的な接続を必要とするリアルタイムアプリに使用するのが一般的で、Phoenixは[1つのサーバーで200万以上の接続を処理する](https://www.phoenixframework.org/blog/the-road-to-2-million-websocket-connections)ことができます。
- 分散クラスタリングはできません
  - Herokuは[dyno間の通信を遮断します](https://devcenter.heroku.com/articles/dynos#networking)。これは、[distributed Phoenix channels](https://dockyard.com/blog/2016/01/28/running-elixir-and-phoenix-projects-on-a-cluster-of-nodes) や [distributed tasks](https://elixir-lang.org/getting-started/mix-otp/distributed-tasks.html) のようなものは、Elixirの組み込みディストリビューションではなく、Redisのようなものに頼る必要があることを意味します。
- [PlugAgent](https://elixir-lang.org/getting-started/mix-otp/agent.html)、[GenServers](https://elixir-lang.org/getting-started/mix-otp/genserver.html)、[ETS](https://elixir-lang.org/getting-started/mix-otp/ets.html)などのインメモリの状態は24時間ごとに失われます。
  - Herokuは、ノードがhealthyかどうかに関わらず、24時間ごとに[dynosを再起動](https://devcenter.heroku.com/articles/dynos#restarting)します。
- Herokuでは[ビルトインのオブザーバー](https://elixir-lang.org/getting-started/debugging.html#observer)は使用できません。
  - Herokuではdynoへの接続は可能ですが、オブザーバーを使ってdynoの状態を見ることはできません。

まだ始めたばかりの方や、上記の機能を使用することを想定していない方は、Herokuで十分です。たとえば、Heroku上で動作している既存のアプリケーションをPhoenixに移行する場合、似たような機能を維持したままであれば、Elixirは現在のスタックと同等かそれ以上のパフォーマンスを発揮します。

このような制限のないプラットフォーム・アズ・ア・サービス(PaaS)が必要な場合は、[Gigalixir](http://gigalixir.readthedocs.io/)を試してみてください。EC2やGoogle Cloudなどのクラウドプラットフォームにデプロイしたい場合は、[Distillery](https://github.com/bitwalker/distillery)を検討してみてください。

## ステップ

このプロセスをいくつかのステップに分けて、現在地を把握できるようにしておきましょう。

- Gitリポジトリの初期化
- Herokuにサインアップする
- Herokuツールベルトのインストール
- Herokuアプリケーションの作成と設定
- プロジェクトをHerokuに対応させる
- デプロイタイム!
- 便利なHekokuコマンド

## Gitリポジトリの初期化

[Git](https://git-scm.com/)は人気のある分散型リビジョン管理システムで、Herokuへのアプリのデプロイにも使われています。

Herokuへプッシュする前に、ローカルのGitリポジトリを初期化してファイルをコミットする必要があります。プロジェクトディレクトリで以下のコマンドを実行します。

```console
$ git init
$ git add .
$ git commit -m "Initial commit"
```

HerokuはGitをどのように使っているのか、素晴らしい情報を[こちら](https://devcenter.heroku.com/articles/git#tracking-your-app-in-git)で提供しています。

## Herokuにサインアップする

Herokuへの登録は非常に簡単で、[https://signup.heroku.com/](https://signup.heroku.com/) に向かい、フォームに必要事項を記入するだけです。

無料プランでは、ウェブ[dyno](https://devcenter.heroku.com/articles/dynos#dynos)とワーカーdyno、PostgreSQLとRedisのインスタンスが無料で利用できます。

これらはテストや開発に使用することを目的としており、いくつかの制限があります。本番アプリケーションを実行するためには、有料プランへのアップグレードをご検討ください。

## Herokuツールベルトのインストール

サインアップしたら、私たちのシステム用に正しいバージョンのHerokuツールベルトを[ここから](https://toolbelt.heroku.com/)ダウンロードできます。

ツールベルトの一部であるHeroku CLIは、Herokuアプリケーションを作成したり、既存のアプリケーションで現在実行中のdynoをリストアップしたり、ログを表示したり、Mixタスクなどの単発のコマンドを実行したりするのに便利です。

## Herokuアプリケーションの作成と設定

Heroku上にPhoenixアプリをデプロイするには、2つの異なる方法があります。Herokuビルドパックまたはそれらのコンテナスタックを使用できます。これら2つのアプローチの違いは、Herokuにビルドを処理するように指示する方法にあります。ビルドパックの場合、Phoenix/Elixir固有のビルドパックを使用するために、Heroku上でアプリの設定を更新する必要があります。コンテナアプローチでは、アプリをどのように設定するかをよりコントロールでき、`Dockerfile` と `heroku.yml` を使ってコンテナイメージを定義できます。このセクションでは、ビルドパックのアプローチについて説明します。Dockerfileを使用するためには、後ほど説明するリリースを使用するようにアプリを変換することが推奨されます。

### アプリケーションを作成する

[ビルドパック](https://devcenter.heroku.com/articles/buildpacks)は、フレームワークやランタイムのサポートをパッケージ化する便利な方法です。PhoenixをHeroku上で動かすには2つのビルドパックが必要で、1つ目のビルドパックは基本的なElixirのサポートを追加し、2つ目のビルドパックはPhoenix固有のコマンドを追加します。

ツールベルトをインストールした状態で、Herokuアプリケーションを作成してみましょう。ここでは、[Elixirビルドパック](https://github.com/HashNuke/heroku-buildpack-elixir)の最新版を使用します。

```console
$ heroku create --buildpack hashnuke/elixir
Creating app... done, ⬢ mysterious-meadow-6277
Setting buildpack to hashnuke/elixir... done
https://mysterious-meadow-6277.herokuapp.com/ | https://git.heroku.com/mysterious-meadow-6277.git
```
> 注意：初めてHerokuコマンドを使うときに、ログインを促されることがあります。その場合は、サインアップ時に指定したメールアドレスとパスワードを入力してください。

> 注意：Herokuアプリケーションの名前は、上の出力の「作成」の後のランダムな文字列（mysterious-meadow-6277）になります。これは一意になりますので、「mysterious-meadow-6277」とは異なる名前が表示されることを期待してください。

> 注意：出力されたURLはアプリケーションへのURLです。今ブラウザで開くと、デフォルトのHerokuウェルカムページが表示されます。

> 注意: もし `heroku create` コマンドを実行する前にGitリポジトリを初期化していなかったら、この時点ではHerokuのリモートリポジトリは適切に設定されていません。これを手動で設定するには、`heroku git:remote -a [ our-app-name].` を実行します。

ビルドパックは定義済みのElixirとErlangのバージョンを使用しますが、デプロイ時に驚かずに済むように、本番で使用するElixirとErlangのバージョンを明示的にリストアップして、開発中やCIサーバーで使用しているものと同じものにするのがベストです。これはプロジェクトのルートディレクトリに `elixir_buildpack.config` という名前のコンフィグファイルを作成して、ターゲットとするElixirとErlangのバージョンを指定します。

```
# Elixir version
elixir_version=1.8.1

# Erlang version
# available versions https://github.com/HashNuke/heroku-buildpack-elixir-otp-builds/blob/master/otp-versions
erlang_version=21.2.5
```

### Phoenixサーバーとアセットのビルドパックの追加

本番環境でPhoenixをうまく動かすためには、アセットをコンパイルしてPhoenixサーバーを起動する必要があります。[Phoenix Staticビルドパック](https://github.com/gjaldon/heroku-buildpack-phoenix-static)がそれを代行してくれるので、早速追加してみましょう。

```console
$ heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
Buildpack added. Next release on mysterious-meadow-6277 will use:
  1. https://github.com/HashNuke/heroku-buildpack-elixir.git
  2. https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
```

このPhoenix Staticビルドパックは、ノードのバージョンやアセットコンパイルのオプションを変更できるように設定できます。詳細は[設定のセクション](https://github.com/gjaldon/heroku-buildpack-phoenix-static#configuration)を参照してください。独自のカスタムビルドスクリプトを作成することもできますが、今のところは[提供されているデフォルトのもの](https://github.com/gjaldon/heroku-buildpack-phoenix-static/blob/master/compile)を使用します。

Phoenix Staticビルドパックは、アプリケーションを起動するために適切なコマンドを使用するようにHerokuを設定します。Elixirビルドパックはデフォルトで `mix run --no-halt` を実行しますが、これはPhoenixサーバーを起動しません。Phoenix Staticビルドパックでは、これを適切な `mix phx.server` に変更します。Phoenix Staticビルドパックを使用したくない場合は、アプリケーションのルートに適切なコマンドを記述した `Procfile` を手動で定義する必要があります。

```
web: mix phx.server
```

Herokuはこのファイルを認識し、アプリケーションを起動するコマンドを使用してPhoenixサーバーも起動するようにします。

最後に、複数のビルドパックを使用しているので、順番が狂っている問題に遭遇する可能性があることに注意してください (ElixirビルドパックはPhoenix Staticビルドパックの前に実行する必要があります)。これについては [Heroku's docs](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app) がよりよく説明していますが、Phoenix Staticビルドパックが最後に来ることを確認する必要があります。

## プロジェクトをHerokuに対応させる

すべての新しいPhoenixプロジェクトには、設定ファイル `config/prod.secret.exs` が同梱されており、これは[環境変数](https://devcenter.heroku.com/articles/config-vars)から設定とシークレットをロードします。これはHerokuのベストプラクティスに沿ったものなので、私たちに残された作業はURLとSSLを設定することだけです。

まず、PhoenixにHerokuのURLを使用するように指示し、SSLバージョンのウェブサイトのみを使用するように強制します。また、Herokuが要求したポートを[`$PORT` 環境変数](https://devcenter.heroku.com/articles/runtime-principles#web-servers)にバインドします。`config/prod.exs`の中にあるURLの行を探してください。

```elixir
url: [host: "example.com", port: 80],
```

そして次のように置き換えてください（`mysterious-meadow-6277`をアプリケーション名に置き換えることを忘れないでください）。

```elixir
http: [port: {:system, "PORT"}],
url: [scheme: "https", host: "mysterious-meadow-6277.herokuapp.com", port: 443],
force_ssl: [rewrite_on: [:x_forwarded_proto]],
```

次に `config/prod.secret.exs` を開き、リポジトリの設定で `# ssl: true,` の行のコメントを外してください。このようになります。

```elixir
config :hello, Hello.Repo,
  ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

最後に、もしWebSocketを使う予定があるならば、`lib/hello_web/endpoint.ex`でWebSocket接続のタイムアウトを減らす必要があります。WebSocketを使用する予定がない場合は、この設定をfalseにしておいても構いません。オプションの詳細な説明は [ドキュメント](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration) にあります。

```elixir
defmodule HelloWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :hello

  socket "/socket", HelloWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  ...
end
```

これにより、idle状態の接続はHerokuの55秒のタイムアウト・ウィンドウに達する前にPhoenixによって閉じられます。

## Herokuで環境変数を作成する

[Heroku Postgresアドオン](https://elements.heroku.com/addons/heroku-postgresql)を追加すると、`DATABASE_URL` の設定ファイルが自動的に作成されます。Herokuのツールベルトを使ってデータベースを作成できます。

```console
$ heroku addons:create heroku-postgresql:hobby-dev
```

ここでは、`POOL_SIZE`を設定します。

```console
$ heroku config:set POOL_SIZE=18
```

この値は利用可能な接続数以下であるべきで、マイグレーションやMixタスクのためにいくつかの空きを残しておく必要があります。hobby-devデータベースでは20の接続が可能なので、この値を18に設定します。データベースを共有するdynoが増える場合は、`POOL_SIZE`の値を小さくして、各dynoが等しく共有できるようにします。

後ほど(プロジェクトをHerokuにプッシュした後に)Mixタスクを実行する際には、プールサイズを以下のように制限したいでしょう。

```console
$ heroku run "POOL_SIZE=2 mix hello.task"
```

これにより、Ectoは利用可能な接続数以上の接続を開こうとしないようになります。

ランダムな文字列に基づいて `SECRET_KEY_BASE` を設定しなければなりません。まず、`mix phx.gen.secret` を使って新しいシークレットを取得します。

```console
$ mix phx.gen.secret
xvafzY4y01jYuzLm3ecJqo008dVnU3CN4f+MamNd1Zue4pXvfvUjbiXT8akaIF53
```

あなたのランダムな文字列は異なるものになります。

これをHerokuに設定します。

```console
$ heroku config:set SECRET_KEY_BASE="xvafzY4y01jYuzLm3ecJqo008dVnU3CN4f+MamNd1Zue4pXvfvUjbiXT8akaIF53"
Setting config vars and restarting mysterious-meadow-6277... done, v3
SECRET_KEY_BASE: xvafzY4y01jYuzLm3ecJqo008dVnU3CN4f+MamNd1Zue4pXvfvUjbiXT8akaIF53
```

## デプロイタイム!

私たちのプロジェクトは、これでHerokuにデプロイする準備が整いました。

すべての変更をコミットしてみましょう。

```console
$ git add config/prod.exs
$ git add elixir_buildpack.config
$ git add phoenix_static_buildpack.config
$ git add lib/hello_web/endpoint.ex
$ git commit -m "Use production config from Heroku ENV variables and decrease socket timeout"
```

そしてデプロイを行います。

```console
$ git push heroku master
Counting objects: 55, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (49/49), done.
Writing objects: 100% (55/55), 48.48 KiB | 0 bytes/s, done.
Total 55 (delta 1), reused 0 (delta 0)
remote: Compressing source files... done.
remote: Building source:
remote:
remote: -----> Multipack app detected
remote: -----> Fetching custom git buildpack... done
remote: -----> elixir app detected
remote: -----> Checking Erlang and Elixir versions
remote:        WARNING: elixir_buildpack.config wasn't found in the app
remote:        Using default config from Elixir buildpack
remote:        Will use the following versions:
remote:        * Stack cedar-14
remote:        * Erlang 17.5
remote:        * Elixir 1.0.4
remote:        Will export the following config vars:
remote:        * Config vars DATABASE_URL
remote:        * MIX_ENV=prod
remote: -----> Stack changed, will rebuild
remote: -----> Fetching Erlang 17.5
remote: -----> Installing Erlang 17.5 (changed)
remote:
remote: -----> Fetching Elixir v1.0.4
remote: -----> Installing Elixir v1.0.4 (changed)
remote: -----> Installing Hex
remote: 2015-07-07 00:04:00 URL:https://s3.amazonaws.com/s3.hex.pm/installs/1.0.0/hex.ez [262010/262010] ->
"/app/.mix/archives/hex.ez" [1]
remote: * creating /app/.mix/archives/hex.ez
remote: -----> Installing rebar
remote: * creating /app/.mix/rebar
remote: -----> Fetching app dependencies with mix
remote: Running dependency resolution
remote: Dependency resolution completed successfully
remote: [...]
remote: -----> Compiling
remote: [...]
remote: Generated phoenix_heroku app
remote: [...]
remote: Consolidated protocols written to _build/prod/consolidated
remote: -----> Creating .profile.d with env vars
remote: -----> Fetching custom git buildpack... done
remote: -----> Phoenix app detected
remote:
remote: -----> Loading configuration and environment
remote:        Loading config...
remote:        [...]
remote:        Will export the following config vars:
remote:        * Config vars DATABASE_URL
remote:        * MIX_ENV=prod
remote:
remote: -----> Installing binaries
remote:        Downloading node 0.12.4...
remote:        Installing node 0.12.4...
remote:        Using default npm version
remote:
remote: -----> Building dependencies
remote:        [...]
remote:               Building Phoenix static assets
remote:        07 Jul 00:06:22 - info: compiled 3 files into 2 files, copied 3 in 3616ms
remote:        Check your digested files at 'priv/static'.
remote:
remote: -----> Finalizing build
remote:        Creating runtime environment
remote:
remote: -----> Discovering process types
remote:        Procfile declares types     -> (web)
remote:        Default types for Multipack -> web
remote:
remote: -----> Compressing... done, 82.1MB
remote: -----> Launching... done, v5
remote:        https://mysterious-meadow-6277.herokuapp.com/ deployed to Heroku
remote:
remote: Verifying deploy... done.
To https://git.heroku.com/mysterious-meadow-6277.git
 * [new branch]      master -> master
```

ターミナルで `heroku open` と入力すると、Phoenixのウェルカムページを開いたブラウザが起動するはずです。データベースにアクセスするためにEctoを使用している場合、最初のデプロイの後にマイグレーションを実行する必要があります。

```console
$ heroku run "POOL_SIZE=2 mix ecto.migrate"
```

それだけです！

## コンテナスタックを使ったHerokuへのデプロイ

### Herokuアプリを作成する

アプリのスタックを `container` に設定すると、`Dockerfile` を使ってアプリのセットアップを定義できます。

```console
$ heroku create
Creating app... done, ⬢ mysterious-meadow-6277
$ heroku stack:set container
```

新しい `heroku.yml` ファイルをルートフォルダに追加します。このファイルでは、アプリで使用するアドオン、イメージのビルド方法、イメージに渡すconfigを定義できます。Herokuの `heroku.yml` オプションの詳細については [こちら](https://devcenter.heroku.com/articles/build-docker-images-heroku-yml) を参照してください。以下はサンプルです。

```yaml
setup:
  addons:
    - plan: heroku-postgresql
      as: DATABASE
build:
  docker:
    web: Dockerfile
  config:
    MIX_ENV: prod
    SECRET_KEY_BASE: $SECRET_KEY_BASE
    DATABASE_URL: $DATABASE_URL
```

### リリースとDockerfileの設定

ここで、アプリケーションを含むプロジェクトのルートフォルダに `Dockerfile` を定義する必要があります。その際にはリリースを使うことをオススメします。リリースを使うことで、自分たちが実際に利用しているErlangとElixirの一部だけを使ってコンテナをビルドすることができるからです。[release docs](/releases.html)にしたがってください。ガイドの最後にはDockerfileのサンプルファイルがあります。

イメージの定義を設定したら、アプリをherokuにプッシュすると、イメージのビルドとデプロイが開始されるのがわかります。

## 便利なHerokuコマンド

プロジェクトディレクトリで以下のコマンドを実行することで、アプリケーションのログを見ることができます。

```console
$ heroku logs # use --tail if you want to tail them
```

また、端末に接続されたIExセッションを起動して、アプリの環境で実験することもできます。

```console
$ heroku run "POOL_SIZE=2 iex -S mix"
```

実際には、上のEctoマイグレーションタスクのように、`heroku run`コマンドを使って何でも実行できます。

```console
$ heroku run "POOL_SIZE=2 mix ecto.migrate"
```

## dynoへの接続

Herokuでは、データベースクエリなどのElixirコードを実行できるように、IExシェルを使ってdynoに接続する機能を提供しています。

- Procfileの`web`プロセスを修正して、名前付きノードを実行するようにしてください。
  ```
  web: elixir -sname server -S mix phx.server
  ```
- Herokuに再度デプロイします
- `heroku ps:exec` でdynoに接続します (同じリポジトリに複数のアプリケーションがある場合は、`--app APP_NAME` または `--remote REMOTE_NAME` でアプリ名またはリモート名を指定する必要があります)。
- `iex -sname console --remsh server` でiexセッションを起動する。

dynoにiexのセッションが入っていますね!

## トラブルシューティング

### コンパイルエラー

時々、アプリケーションがローカルでコンパイルされることがありますが、Heroku上ではコンパイルされません。Heroku上でのコンパイルエラーは以下のようになります。

```console
remote: == Compilation error on file lib/postgrex/connection.ex ==
remote: could not compile dependency :postgrex, "mix compile" failed. You can recompile this dependency with "mix deps.compile postgrex", update it with "mix deps.update postgrex" or clean it with "mix deps.clean postgrex"
remote: ** (CompileError) lib/postgrex/connection.ex:207: Postgrex.Connection.__struct__/0 is undefined, cannot expand struct Postgrex.Connection
remote:     (elixir) src/elixir_map.erl:58: :elixir_map.translate_struct/4
remote:     (stdlib) lists.erl:1353: :lists.mapfoldl/3
remote:     (stdlib) lists.erl:1354: :lists.mapfoldl/3
remote:
remote:
remote:  !     Push rejected, failed to compile elixir app
remote:
remote: Verifying deploy...
remote:
remote: !   Push rejected to mysterious-meadow-6277.
remote:
To https://git.heroku.com/mysterious-meadow-6277.git
```

これは、適切に再コンパイルされない古い依存関係に関係しています。Herokuはデプロイのたびにすべての依存関係を再コンパイルするように強制できます。その方法は、アプリケーションのルートに `elixir_buildpack.config` という新しいファイルを追加することです。このファイルには以下の行が含まれていなければなりません。

```
always_rebuild=true
```

このファイルをリポジトリにコミットして、再度Herokuにプッシュしてみてください。

### コネクションタイムアウトエラー

`heroku run`を実行している間、常にコネクションのタイムアウトが発生する場合は、インターネットプロバイダがポート番号5000をブロックしている可能性があります。

```console
heroku run "POOL_SIZE=2 mix myapp.task"
Running POOL_SIZE=2 mix myapp.task on mysterious-meadow-6277... !
ETIMEDOUT: connect ETIMEDOUT 50.19.103.36:5000
```

コマンドを実行する際に `detached` オプションを追加することで、この問題を解決できます。

```console
heroku run:detached "POOL_SIZE=2 mix ecto.migrate"
Running POOL_SIZE=2 mix ecto.migrate on mysterious-meadow-6277... done, run.8089 (Free)
```