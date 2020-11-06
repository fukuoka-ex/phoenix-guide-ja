---
layout: 1.5/layout
version: 1.5
group: introduction
title: 起動
nav_order: 3
hash: daa02353
---
# 起動

Phoenixのアプリケーションをできるだけ早く起動させましょう。

始める前に、[インストールガイド](install.html)を少しだけお読みください。必要な依存関係を事前にインストールしておくことで、スムーズにアプリケーションを立ち上げることができます。

Phoenixアプリケーションを起動するために、どのディレクトリからでも `mix phx.new` を実行することができます。Phoenixは、新しいプロジェクトのディレクトリに絶対パスか相対パスのどちらかを受け入れます。アプリケーションの名前が `hello` であると仮定して、以下のコマンドを実行してみましょう。

```console
$ mix phx.new hello
```

> 始める前の[webpack](https://webpack.js.org/)についての注意。Phoenixはデフォルトでアセット管理にwebpackを使用します。Webpackの依存関係は、ノードのパッケージマネージャを介してインストールされます。Phoenixは `mix phx.new` タスクの最後にそれらをインストールするように促します。この時点で「いいえ」と答え、後で `npm install` で依存関係をインストールしないと、アプリケーションを起動しようとしたときにエラーが発生し、アセットが正しくロードされない可能性があります。webpackを全く使いたくない場合は、単に `--no-webpack` を `mix phx.new` に渡せばよいのです。

> [Ecto](ecto.html)についての注意点。Ectoは、PhoenixアプリケーションがPostgreSQLやMySQLなどのデータストアと通信することを可能にします。アプリケーションがこのコンポーネントを必要としない場合は、 `--no-ecto` フラグを `mix phx.new` に渡すことで、この依存関係をスキップすることができます。このフラグは `--no-webpack` と組み合わせてスケルトンアプリケーションを作成することもできます。

> `mix phx.new` の詳細については、[Mixタスクガイド](mix_tasks.html#phoenix-specific-mix-tasks)を参照してください。

```console
mix phx.new hello
* creating hello/config/config.exs
* creating hello/config/dev.exs
* creating hello/config/prod.exs
...
* creating hello/assets/static/images/phoenix.png
* creating hello/assets/static/favicon.ico

Fetch and install dependencies? [Yn]
```

Phoenixは、ディレクトリ構造とアプリケーションに必要なすべてのファイルを生成します。

> Phoenixはバージョン管理ソフトウェアとして gitを使うことを推奨しています。生成されたファイルの中には `.gitignore` というファイルがあります。リポジトリを `git init` して、無視されていないものをすぐに追加してコミットすることができます。

それが終わると、依存関係をインストールするかどうかを尋ねてきます。これにイエスと答えましょう。

```console
Fetch and install dependencies? [Yn] Y
* running mix deps.get
* running mix deps.compile
* running cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development

We are almost there! The following steps are missing:

    $ cd hello

Then configure your database in config/dev.exs and run:

    $ mix ecto.create

Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server
```

依存関係がインストールされると、タスクはプロジェクトディレクトリに変更してアプリケーションを起動するように促します。

Phoenixは、PostgreSQLデータベースが正しいパーミッションとパスワード"postgres"を持つ`postgres`ユーザーアカウントを持っていることを前提としています。そうでない場合は、`mix ecto.create`タスクの詳細について[Mixタスクガイド](mix_tasks.html#ecto-specific-mix-tasks)を参照してください。

それでは、試してみましょう。まず、先ほど作成した `hello/` ディレクトリに `cd` します。

```console
$ cd hello
```

> [インストールガイド](installation.html)に従って、`{:cowboy, "~> 2.7.0"}`をmix.exsに追加することを選択した場合は、`mix deps.get`を実行してください。

では、データベースを作成します。

```console
$ mix ecto.create
Compiling 13 files (.ex)
Generated hello app
The database for Hello.Repo has been created
```

データベースが作成できなかった場合、一般的なトラブルシューティングについては、[`mix ecto.create`](mix_tasks.html#mix-ecto-create)のガイドを参照してください。

> 注意: このコマンドを初めて実行する場合、PhoenixはRebarのインストールを要求してくるかもしれません。RebarはErlangパッケージのビルドに使われるので、インストールを進めてください。

そして最後にPhoenixサーバーを起動します。

```console
$ mix phx.server
[info] Running HelloWeb.Endpoint with cowboy 2.5.0 at http://localhost:4000

Webpack is watching the files…
...
```

新しいアプリケーションを生成するときに依存関係をインストールしないように選択した場合、`mix phx.new`タスクは、依存関係をインストールしたいときに必要なステップを踏むように促してくれます。

```console
Fetch and install dependencies? [Yn] n

We are almost there! The following steps are missing:

    $ cd hello
    $ mix deps.get
    $ cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development

Then configure your database in config/dev.exs and run:

    $ mix ecto.create

Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server
```

デフォルトでは、Phoenixは4000番ポートでリクエストを受け付けます。お気に入りのウェブブラウザを[http://localhost:4000](http://localhost:4000)に向けると、Phoenix Frameworkのウェルカムページが表示されるはずです。

![Phoenixウェルカムページ](assets/images/welcome-to-phoenix.png)

上の画像のような画面が表示されたら、おめでとうございます。これでPhoenixアプリケーションが動作します。上のページが表示されない場合は、[http://127.0.0.1:4000](http://127.0.0.1:4000)からアクセスしてみてください。

これを止めるには、`ctrl-c`を2回入力します。

これで、Phoenixが提供する世界を探検する準備が整いました!書籍、スクリーンキャスト、コースなどについては、[コミュニティページ](community.html)をご覧ください。

あるいは、これらのガイドを読み続けて、Phoenixアプリケーションを構成するすべての部分を簡単な紹介を得ることができます。その場合は、任意の順番でガイドを読むこともできますし、[Phoenixディレクトリ構造](directory_structure.html)について説明しているガイドから始めることもできます。

