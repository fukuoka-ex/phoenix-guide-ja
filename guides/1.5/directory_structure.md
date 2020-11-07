---
layout: 1.5/layout
version: 1.5
group: guides
title: ディレクトリ構造
nav_order: 1
hash: 1328b063
---
# ディレクトリ構造

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています。

新しいPhoenixアプリケーションを生成するために `mix phx.new` を使用すると、以下のようなトップレベルのディレクトリ構造が構築されます。

```console
├── _build
├── assets
├── config
├── deps
├── lib
│   └── hello
│   └── hello.ex
│   └── hello_web
│   └── hello_web.ex
├── priv
└── test
```

それらのディレクトリを1つ1つ見ていきましょう。

  * `_build` - Elixirの一部として提供されている `mix` コマンドラインツールによって作成されたディレクトリで、すべてのコンパイルアーティファクトを保持しています。"起動ガイド"で見たように、`mix` はアプリケーションのメインインターフェイスです。Mixを使ってコードをコンパイルしたり、データベースを作成したり、サーバーを起動したりします。このディレクトリはバージョン管理に含めてはならず、いつでも削除できます。このディレクトリを削除すると、アプリケーションをゼロからビルドしなければなりません。

  * `assets` - JavaScript、CSS、静的画像など、フロントエンドのアセットに関連するすべてのものを保持するディレクトリです。通常は `npm` ツールで処理されます。Phoenixの開発者は通常、assetsディレクトリ内で `npm install` を実行するだけで済みます。それ以外はすべてPhoenixが管理します。

  * `config` - プロジェクトの設定を保持するディレクトリです。`config/config.exs` ファイルは、設定のためのメインのエントリーポイントです。`config/config.exs` の最後には、`config/dev.exs`, `config/test.exs`, `config/prod.exs` に記述されている環境固有の設定をインポートします。

  * `deps` - Mixのすべての依存関係があるディレクトリです。すべての依存関係は、`def deps do` 関数定義の中の `mix.exs` ファイルに記載されています。このディレクトリはバージョン管理に含めてはならず、いつでも削除できます。このディレクトリを削除すると、Mixはすべてのdepsをイチからダウンロードするように強制されます。

  * `lib` - アプリケーションのソースコードを保持するディレクトリです。このディレクトリは、`lib/hello` と `lib/hello_web` の2つのサブディレクトリに分かれています。`lib/hello` ディレクトリは、すべてのビジネスロジックとビジネスドメインを提供します。これは通常、データベースと直接対話します。Model-View-Controller (MVC) アーキテクチャの"モデル"に相当します。`lib/hello_web` は、この場合はwebアプリケーションを介して、ビジネスドメインを外部に公開する役割を担います。MVCのビューとコントローラーの両方を保持しています。これらのディレクトリの内容については、次のセクションで詳しく説明します。

  * `priv` - 本番で必要とされるが、ソースコードの一部ではないすべてのアセットを保管するディレクトリです。通常、データベーススクリプトや翻訳ファイルなどはここに保管します。

  * `test` - すべてのアプリケーションテストが入っているディレクトリです。多くの場合、`lib` の中にあるのと同じ構造になっています。

## lib/helloディレクトリ

`lib/hello` ディレクトリはあなたのビジネスドメインのすべてを提供します。私たちのプロジェクトはまだビジネスロジックを持っていないので、このディレクトリはほとんど空です。見つかるのは2つのファイルだけです。

```console
lib/hello
├── application.ex
└── repo.ex
```

ファイル `lib/hello/application.ex` は、`Hello.Application` という名前のElixirアプリケーションを定義しています。これは、Phoenixのアプリケーションは結局のところ、単にElixirのアプリケーションだからです。`Hello.Application`モジュールは、どのサービスがアプリケーションの一部であるかを定義しています。

```elixir
children = [
  # Start the Ecto repository
  Hello.Repo,
  # Start the Telemetry supervisor
  HelloWeb.Telemetry,
  # Start the PubSub system
  {Phoenix.PubSub, name: Hello.PubSub},
  # Start the Endpoint (http/https)
  HelloWeb.Endpoint
  # Start a worker by calling: Hello.Worker.start_link(arg)
  # {Hello.Worker, arg}
]
```

はじめてPhoenixを使用する場合は、今は詳細を心配する必要はありません。今のところ、私たちのアプリケーションは、データベースリポジトリ、プロセスやノード間でメッセージを共有するためのpubsubシステム、そしてHTTPリクエストを効果的に処理するアプリケーションエンドポイントを起動すると言っておけば十分です。これらのサービスは定義された順番で起動され、アプリケーションをシャットダウンするときはいつでも逆の順番で停止します。

アプリケーションについては、[Elixir公式ドキュメントのApplication](https://hexdocs.pm/elixir/Application.html)で詳しく解説しています。

同じ `lib/hello` ディレクトリに `lib/hello/repo.ex` があります。これはデータベースへのメインインターフェイスである `Hello.Repo` モジュールを定義しています。Postgres(デフォルト)を使用している場合、以下のようなものが表示されます。

```elixir
defmodule Hello.Repo do
  use Ecto.Repo,
    otp_app: :hello,
    adapter: Ecto.Adapters.Postgres
end
```

そして、今のところはこれで終わりです。プロジェクトを進めていくうちに、このディレクトリにファイルやモジュールを追加していきます。

## lib/hello_webディレクトリ

`lib/hello_web` ディレクトリには、アプリケーションのウェブに関連した部分が格納されています。展開すると以下のようになります。

```console
lib/hello_web
├── channels
│   └── user_socket.ex
├── controllers
│   └── page_controller.ex
├── templates
│   ├── layout
│   │   └── app.html.eex
│   └── page
│       └── index.html.eex
├── views
│   ├── error_helpers.ex
│   ├── error_view.ex
│   ├── layout_view.ex
│   └── page_view.ex
├── endpoint.ex
├── gettext.ex
├── router.ex
└── telemetry.ex
```

現在 `controllers`、`templates`、`views` ディレクトリにあるすべてのファイルは、"起動"ガイドで見た "Welcome to Phoenix!"ページを作成するためのものです。
`channels` ディレクトリは、リアルタイムのPhoenixアプリケーションの構築に関連するコードを追加する場所です。

`template`と`views`のディレクトリを見ると、Phoenixはレイアウトやエラーページを処理するための機能を提供していることがわかります。

これらのディレクトリの他に、`lib/hello_web`はルートに4つのファイルを持っています。`lib/hello_web/endpoint.ex` はHTTPリクエストのエントリーポイントです。ブラウザが `http://localhost:4000` にアクセスすると、エンドポイントはデータの処理を開始し、最終的には `lib/hello_web/router.ex` で定義されているルータにたどり着きます。ルーターは「コントローラー」にリクエストをディスパッチするためのルールを定義し、「ビュー」と「テンプレート」を使ってHTMLページをクライアントに返すようにします。これらのレイヤーについては次の「リクエストライフサイクル」から始まる他のガイドで詳しく説明しています。

*telemetry*を通じて、Phoenixはアプリケーションのメトリクスを収集し、監視イベントを送信することができます。`lib/hello_web/telemetry.ex` ファイルは、テレメトリプロセスを管理するスーパーバイザーを定義しています。このトピックに関する詳細な情報は、[Telemetryガイド](telemetry.html)を参照してください。

最後に、`lib/hello_web/gettext.ex` ファイルがあり、これは [Gettext](https://hexdocs.pm/gettext/Gettext.html) を通じて国際化を提供します。国際化を気にしないのであれば、このファイルとその内容はスキップしても問題ありません。
