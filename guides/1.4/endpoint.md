---
layout: 1.4/layout
version: 1.4
group: guides
title: エンドポイント
nav_order: 5
hash: 706f3f036c5f14b48fe8278fab3735c05d1fbfa1
---

# エンドポイント

Phoenixアプリケーションは、HelloWeb.Endpointを監視下のプロセスとして開始します。デフォルトでは、エンドポイントは`lib/hello/application.ex`の監視対象プロセスとして監視対象ツリーに追加されます。各リクエストはエンドポイントでアプリケーション内でライフサイクルを開始し、終了します。エンドポイントは、[ルーター]](routing.html)を呼び出す前に、ウェブサーバを起動し、いくつかの定義されたプラグを通してリクエストを変換する処理を行います。

```elixir
defmodule Hello.Application do
  use Application
  def start(_type, _args) do
    ...

    children = [
      HelloWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### エンドポイントの内容

エンドポイントは共通の機能を集め、アプリケーションへのすべてのHTTPリクエストの入り口と出口として機能します。エンドポイントは、アプリケーションに入ってくるすべてのリクエストに共通するプラグを保持します。

[起動ガイド](up_and_running.html) ページで生成されたアプリケーション`Hello`のエンドポイントを見てみましょう。

```elixir
defmodule HelloWeb.Endpoint do
  ...
end
```

Endpointモジュールの最初の呼び出しは、`otp_app`を持つ`use Phoenix.Endpoint`マクロです。この `otp_app`は設定に使われます。これは`HelloWeb.Endpoint`モジュール上のいくつかの関数を定義しています。

```elixir
use Phoenix.Endpoint, otp_app: :hello
```

次に、エンドポイントは"/socket"URIにソケットを宣言します。"/socket"リクエストは、アプリケーションの他の場所で宣言されている`HelloWeb.UserSocket`モジュールによって処理されます。ここでは、このようなコネクションが存在することを宣言しているだけです。

```elixir
socket "/socket", HelloWeb.UserSocket,
  websocket: true,
  longpoll: false
```

次に、アプリケーション内のすべてのリクエストに関連する一連のプラグが登場します。たとえば、本番環境へデプロイする際に`gzip: true`を有効にして静的ファイルをgzipするなど、いくつかの機能をカスタマイズできます。

静的ファイルは、リクエストがルーターへ届く前に `priv/static` から提供されます。

```elixir
plug Plug.Static,
  at: "/",
  from: :hello,
  gzip: false,
  only: ~w(css fonts images js favicon.ico robots.txt)
```

コードのリロードが有効になっている場合、サーバー上でコードが変更されたときに、ページをリロードする必要があることをブラウザへ伝えるためにソケットが使用されます。この機能は開発環境ではデフォルトで有効になっています。これは`config :hello, HelloWeb.Endpoint, code_reloader: true`で設定します。

```elixir
if code_reloading? do
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader
end
```

[Plug.RequestId](https://hexdocs.pm/plug/Plug.RequestId.html)は各リクエストに固有のIDを生成し、[Plug.Telemetry](https://hexdocs.pm/plug/Plug.Telemetry.html)は計測ポイントを追加して、Phoenixがデフォルトでリクエストパス、ステータスコード、リクエスト時間をログに記録できるようにします。

```elixir
plug Plug.RequestId
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
```

[Plug.Session](https://hexdocs.pm/plug/Plug.Session.html)は、セッションクッキーとセッションストアを処理します。

```elixir
plug Plug.Session, @session_options
```

デフォルトでは、エンドポイントの最後のプラグはルーターです。ルーターは、特定のコントローラーアクションまたはプラグへのパスにマッチします。ルータについては、[ルーティングガイド](routing.html)で説明しています。

```elixir
plug HelloWeb.Router
```

エンドポイントをカスタマイズしてプラグを追加し、HTTPベーシック認証、CORS、サブドメインルーティングなどを有効にできます。

Ecto Repoのような監視ツリーの異なる部分で障害が発生しても、すぐにメインアプリケーションに影響を与えることはありません。そのため、スーパーバイザーは予期せぬ障害が発生した後に、それらのプロセスを個別に再起動することができます。また、アプリケーションが複数のエンドポイントを持ち、それぞれが独自の監視ツリーを持つことも可能です。

エンドポイントモジュールには、パスヘルパー、チャネルのサブスクリプションとブロードキャスト、インスツルメンテーション、エンドポイント設定のために定義された多くの機能があります。これらはすべて、`Phoenix.Endpoint`の[Endpoint APIドキュメント](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#module-endpoint-api)で説明されています。

## SSLを利用する

アプリケーションがSSLでリクエストに応答するように準備するには、少しの設定と2つの環境変数を追加する必要があります。SSLが実際に動作するためには、認証局の鍵ファイルと証明書ファイルが必要です。必要な環境変数はこれら2つのファイルへのパスです。

設定はエンドポイント用の新しい`https:`キーで構成され、その値はポート、キーファイルへのパス、証明書（pem）ファイルへのパスのキーワードリストです。アプリケーションの名前を表す`otp_app:`キーを追加すると、プラグはアプリケーションのルートでそれらのファイルを探し始めます。これらのファイルを`priv`ディレクトリに置き、パスを`priv/our_keyfile.key`と`priv/our_cert.crt`に設定します。

以下は `config/prod.exs` の設定例です。

```elixir
use Mix.Config

config :hello, HelloWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "example.com"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  https: [
    port: 443,
    cipher_suite: :strong,
    otp_app: :hello,
    keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
    certfile: System.get_env("SOME_APP_SSL_CERT_PATH"),
    # OPTIONAL Key for intermediate certificates:
    cacertfile: System.get_env("INTERMEDIATE_CERTFILE_PATH")
  ]

```

`otp_app:`キーがない場合、プラグがファイルを見つけるためには、ファイルシステム上のどこにあってもファイルへの絶対パスを指定する必要があります。

```elixir
Path.expand("../../../some/path/to/ssl/key.pem", __DIR__)
```

`https:`キーの下にあるオプションはプラグアダプタ（通常は `Plug.Cowboy`）に渡され、プラグアダプタは`Plug.SSL`を使用してTLSソケットのオプションを選択します。利用可能なオプションとそのデフォルト値の詳細については、[Plug.SSL.configure/1](https://hexdocs.pm/plug/Plug.SSL.html#configure/1)のドキュメントを参照してください。[Plug HTTPS Guide](https://hexdocs.pm/plug/https.html) や [Erlang/OTP ssl](http://erlang.org/doc/man/ssl.html) のドキュメントも貴重な情報を提供しています。

### 開発環境でのSSL

開発でHTTPSを使いたい場合、`mix phx.gen.cert`を実行することで自己署名証明書を生成できます。これにはErlang/OTP 20以降が必要です。

自己署名証明書があれば、`config/dev.exs`の設定をHTTPSエンドポイントを実行するように更新できます。

```elixir
config :my_app, MyApp.Endpoint,
  ...
  https: [
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ]
```

これは`http`の設定を置き換えることもできますし、異なるポートでHTTPとHTTPSサーバを実行することもできます。

### 強制SSL化

多くの場合、HTTPをHTTPSにリダイレクトすることで、すべての受信リクエストにSSLを使用させたいと思うでしょう。これはエンドポイントの設定で`:force_ssl`オプションを設定することで実現できます。これは `Plug.SSL`に転送されるオプションのリストを渡す必要があります。デフォルトでは、HTTPSリクエストに "strict-transport-security"ヘッダーが設定され、ブラウザは常にHTTPSを使用するように強制されます。安全でない（HTTP）リクエストが送信された場合、`:url`設定で指定した`:host`を使ってHTTPSバージョンにリダイレクトします。たとえば、以下のようになります。

```elixir
config :my_app, MyApp.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]]
```

現在のリクエストの`host`に動的にリダイレクトするには、`:force_ssl`の設定で`:host`を`nil`に設定してください。

```elixir
config :my_app, MyApp.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto], host: nil]
```

これらの例では、`rewrite_on:`キーは、リバースプロキシやロードバランサーがアプリケーションの前で使用するHTTPヘッダーを指定し、リクエストがHTTPで受信したかHTTPSで受信したかを示します。TLSを外部要素にオフロードすることの意味合い、特にセキュアクッキーに関連する詳細については、[Plug HTTPS Guide](https://hexdocs.pm/plug/https.html#offloading-tls)を参照してください。このドキュメントで`Plug.SSL`に渡されるオプションは、Phoenixアプリケーションの`force_ssl:`エンドポイントオプションを使って設定する必要があることに注意してください。

### HSTS

HSTSまたは"strict-transport-security"は、ウェブサイトが安全な接続（HTTPS）を介してのみアクセス可能であることを宣言できるようにする仕組みです。SSL/TLSを剥奪する中間者攻撃を防ぐために導入されました。これにより、WebブラウザはHTTPからHTTPSにリダイレクトし、SSL/TLSを使用しない限り接続を拒否するようになります。

`force_ssl: :hsts` 設定すると、`Strict-Transport-Security`ヘッダにポリシーの有効期間を定義するmax ageが設定されます。最近のWebブラウザは、標準的なケースではHTTPからHTTPSにリダイレクトすることでこれに対応しますが、他の結果になることもあります。また、HSTSを定義している [RFC6797](https://tools.ietf.org/html/rfc6797) は、**ブラウザがホストのポリシーを追跡し、それが期限切れになるまで適用すること**を規定しています。また、ポリシーに従って、**80以外のポートのトラフィックは暗号化されていることを前提とすること**も指定されています。

これは、`https://localhost:4000`などのローカルホスト上のアプリケーションにアクセスした場合、予期せぬ動作をする可能性があります。これは、コンピューター上で実行している他のローカルサーバやプロキシへのトラフィックを混乱させる可能性があります。localhost上の他のアプリケーションやプロキシは、トラフィックが暗号化されていない限り動作を拒否します。

誤ってlocalhostのHSTSを有効にしてしまった場合、localhostからのHTTPトラフィックを受け入れる前にブラウザのキャッシュをリセットする必要があるかもしれません。Chromeの場合は、デベロッパーツールを起動してリロードアイコンを長押しすると表示されるリロードメニューから、「キャッシュの消去とハード再読み込み」を実行する必要があります。Safariの場合は、キャッシュをクリアし、`~/Library/Cookies/HSTS.plist`のエントリを削除して（またはファイルを完全に削除して）、Safariを再起動する必要があります。あるいは、`force_ssl`の`:expires`オプションを`0`に設定することもできます。HSTSのオプションについての詳細は [Plug.SSL](https://hexdocs.pm/plug/Plug.SSL.html) にあります。
