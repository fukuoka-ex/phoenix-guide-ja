---
layout: 1.5/layout
version: 1.5
group: guides
title: Plug
nav_order: 3
hash: 496e544b
---
# Plug

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: [リクエストライフサイクルのガイド](request_lifecycle.html)を前提としています

PlugはPhoenixのHTTPレイヤー中心にあり、PhoenixはPlugを中心に置いています。エンドポイント、ルーター、コントローラーなどのPhoenixのコアコンポーネントは、内部的にはすべてPlugです。Plugの特徴を確認してみましょう。

[Plug](https://github.com/elixir-lang/plug) は、ウェブアプリケーション間のモジュールを構成するための仕様です。また、異なるWebサーバーのコネクションアダプターの抽象化レイヤーでもあります。Plugの基本的な考え方は、私たちが操作する「コネクション」という概念を統一することです。これは、ミドルウェアスタックの中でリクエストとレスポンスが分離されているRackなどの他のHTTPミドルウェア層とは異なります。

もっとも簡単なレベルでは、Plugの仕様には2つの種類があります。*関数Plug* と*モジュールPlug* です。

## 関数Plug

Plugとして動作するためには、関数はコネクション構造体（`%Plug.Conn{}`）とオプションを受け取る必要があります。また、コネクション構造体を返す必要があります。これらの基準を満たす関数であれば、どのような関数でも動作します。以下に例を示します。

```elixir
def introspect(conn, _opts) do
  IO.puts """
  Verb: #{inspect(conn.method)}
  Host: #{inspect(conn.host)}
  Headers: #{inspect(conn.req_headers)}
  """

  conn
end
```

この関数は以下のようなことを行います。

  1. コネクションとオプション（今回は使用しません）を受け取ります
  2. ターミナルへコネクション情報を表示します
  3. コネクションを返します

とても簡単でしょう？この関数を `lib/hello_web/endpoint.ex` のエンドポイントに追加してみましょう。どこにでも組み込むことができるので、リクエストをルーターへ委譲する前に実行してみましょう。

```elixir
defmodule HelloWeb.Endpoint do
  ...

  plug :introspect
  plug HelloWeb.Router

  def introspect(conn, _opts) do
    IO.puts """
    Verb: #{inspect(conn.method)}
    Host: #{inspect(conn.host)}
    Headers: #{inspect(conn.req_headers)}
    """

    conn
  end
end
```

関数Plugは、関数名をアトムとして渡すことで組み込むことができます。Plugを試すには、ブラウザに戻って "http://localhost:4000" へアクセスします。ターミナルにはこのような表示が出てくるはずです。

```console
Verb: "GET"
Host: "localhost"
Headers: [...]
```

私たちのPlugは、単にコネクションからの情報をプリントするだけのものです。初期のPlugは非常にシンプルですが、Plugの中では事実上何でもできるようになっています。コネクションで利用可能なすべてのフィールドとそれに関連するすべての機能については、 [Plug.Connのドキュメントを参照してください](https://hexdocs.pm/plug/Plug.Conn.html)

では、異なる特徴を持つモジュールPlugを見てみましょう。

## モジュールPlug

モジュールPlugは、モジュール内のコネクション変換を定義するためのPlugの別のタイプです。モジュールは2つの関数を実装するだけです。

- `call/2` に渡される引数やオプションを初期化する `init/1`
- コネクション変換を実行する `call/2` 。`call/2` は先ほど見た関数Plugと同様

これを実際に見るために、`:locale` のキーと値をコネクションのassignに入れるモジュールPlugを書いてみましょう。上記の内容を "lib/hello_web/plugs/locale.ex" というファイルに記述します。

```elixir
defmodule HelloWeb.Plugs.Locale do
  import Plug.Conn

  @locales ["en", "fr", "de"]

  def init(default), do: default

  def call(%Plug.Conn{params: %{"locale" => loc}} = conn, _default) when loc in @locales do
    assign(conn, :locale, loc)
  end

  def call(conn, default) do
    assign(conn, :locale, default)
  end
end
```

試しに、このPlugをルーターに追加してみましょう。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HelloWeb.Plugs.Locale, "en"
  end
  ...
```

このモジュールPlugをブラウザのパイプラインに追加するには、`plug HelloWeb.Plugs.Locale, "en"` を使用します。`init/1` コールバックでは、パラメーターにロケールがない場合に使用するデフォルトのロケールを渡します。また、パターンマッチングを使用して複数の `call/2` 関数を定義してパラメーターのロケールをバリデートし、一致しない場合は "en" にフォールバックします。

assignの動作を見るには、"lib/hello_web/templates/layout/app.html.eex" 内のレイアウトに移動し、メインのコンテナー近くに以下を追加します。

```html
<main role="main" class="container">
  <p>Locale: <%= @locale %></p>
```

"http://localhost:4000/"にアクセスすると、ロケールが表示されているはずです。 "http://localhost:4000/?locale=fr" にアクセスすると、assignが "fr" に変更されているのがわかるはずです。この情報を [Gettext](https://hexdocs.pm/gettext/Gettext.html) と並べて使うことで、完全に国際化されたウェブアプリケーションを提供することができます。

Plugが行うのはこれだけです。Phoenixは隅から隅まで、合成可能な変換のPlugデザインを採用しています。いくつかの例を見てみましょう

## 組み込める場所

Phoenixのエンドポイント、ルーター、コントローラーはPlugを受け入れます。

### エンドポイントPlug

エンドポイントは、すべてのリクエストに共通するすべてのPlugを整理し、カスタムパイプラインでルーターへディスパッチする前に適用します。このようにエンドポイントにPlugを追加しました。

```elixir
defmodule HelloWeb.Endpoint do
  ...

  plug :introspect
  plug HelloWeb.Router
```

デフォルトのエンドポイントPlugはかなり多くの作業を行います。ここでは順を追って説明します。

- [Plug.Static](https://hexdocs.pm/plug/Plug.Static.html) - 静的アセットを提供します。このplugはロガーの前に来るので、静的アセットの提供はログに記録されません。

- [Phoenix.CodeReloader](https://hexdocs.pm/phoenix/Phoenix.CodeReloader.html) - ウェブディレクトリ内のすべてのエントリのコードリロードを可能にするplugです。これはPhoenixアプリケーションで直接設定します。

- [Plug.RequestId](https://hexdocs.pm/plug/Plug.RequestId.html) - 各リクエストに対して一意のリクエストIDを生成します。

- [Plug.Telemetry](https://hexdocs.pm/plug/Plug.Telemetry.html) - 測定ポイントを追加し、Phoenixがデフォルトでリクエストパス、ステータスコード、リクエスト時間をログに記録できるようにします。

- [Plug.Parsers](https://hexdocs.pm/plug/Plug.Parsers.html) - 既知のパーサーが利用可能な場合に、リクエストの本文をパースします。デフォルトでは、パーサーはurlencoded, multipart, json (`jason` にて) をパースします。リクエストのcontent-typeが解析できない場合、リクエストボディはそのままになります。

- [Plug.MethodOverride](https://hexdocs.pm/plug/Plug.MethodOverride.html) - 有効な `_method` パラメーターを持つPOSTリクエストに対して、リクエストメソッドをPUT, PATCH, DELETEに変換します

- [Plug.Head](https://hexdocs.pm/plug/Plug.Head.html) - HEADリクエストをGETリクエストに変換し、レスポンスボディを削除します

- [Plug.Session](https://hexdocs.pm/plug/Plug.Session.html) - セッション管理を設定するplugです。このplugはセッションの取得方法を設定するだけなので、セッションを使う前に `fetch_session/2` が明示的に呼ばれなければならないことに注意してください。

エンドポイントの途中には、条件付きブロックもあります。

```elixir
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :demo
  end
```

このブロックは開発時にのみ実行されます。これは、ライブリロード（CSSファイルを変更した場合、ページを更新せずにブラウザ内で更新されます）、コードリロード（サーバーを再起動せずにアプリケーションの変更を確認できるようにします）、レポジトリステータスのチェック（データベースが最新であることを確認し、そうでない場合は読み取り可能で実行可能なエラーを発生させます）を可能にします。

### ルーターPlug

ルーターでは、パイプライン内でPlugを宣言できます。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HelloWeb.Plugs.Locale, "en"
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
  end
```

ルートはスコープ内で定義され、スコープは複数のパイプラインを通過できます。ルートが一致すると、Phoenixはそのルートに関連付けられたすべてのパイプラインで定義されたすべてのPlugを呼び出します。たとえば、"/" にアクセスすると `:browser` パイプラインを通過し、その結果、すべてのPlugが呼び出されます。

[ルーティングガイド](routing.html)で見るように、パイプライン自体がPlugです。ここでは `:browser` パイプラインのすべてのPlugについても説明します。

### コントローラーPlug

最後に、コントローラーもPlugなので、次のようにできます:

```elixir
defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  plug HelloWeb.Plugs.Locale, "en"
```

とくに、コントローラーPlugは、特定のアクション内でのみPlugを実行できる機能を提供しています。たとえば、次のようなことができます。

```elixir
defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  plug HelloWeb.Plugs.Locale, "en" when action in [:index]
```

この場合、Plugは `index` アクションに対してのみ実行されます。

## 構成としてのPlug

Plugの取り決めを遵守することで、アプリケーションのリクエストを一連の明示的に変換します。これで終わりではありません。Plugの設計がどれほど効果的かを実際に見るために、一連の条件をチェックして、条件が失敗した場合にリダイレクトするか停止する必要があるシナリオを想像してみましょう。Plugがなければ、次のようになるでしょう。

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  def show(conn, params) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        case find_message(params["id"]) do
          nil ->
            conn |> put_flash(:info, "That message wasn't found") |> redirect(to: "/")
          message ->
            if Authorizer.can_access?(user, message) do
              render(conn, :show, page: message)
            else
              conn |> put_flash(:info, "You can't access that page") |> redirect(to: "/")
            end
        end
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: "/")
    end
  end
end
```

認証と認可のわずか数ステップで、複雑な入れ子と重複を必要とすることにお気づきでしょうか？これをいくつかのPlugで改善してみましょう。

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  plug :authenticate
  plug :fetch_message
  plug :authorize_message

  def show(conn, params) do
    render(conn, :show, page: conn.assigns[:message])
  end

  defp authenticate(conn, _) do
    case Authenticator.find_user(conn) do
      {:ok, user} ->
        assign(conn, :user, user)
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: "/") |> halt()
    end
  end

  defp fetch_message(conn, _) do
    case find_message(conn.params["id"]) do
      nil ->
        conn |> put_flash(:info, "That message wasn't found") |> redirect(to: "/") |> halt()
      message ->
        assign(conn, :message, message)
    end
  end

  defp authorize_message(conn, _) do
    if Authorizer.can_access?(conn.assigns[:user], conn.assigns[:message]) do
      conn
    else
      conn |> put_flash(:info, "You can't access that page") |> redirect(to: "/") |> halt()
    end
  end
end
```

これをすべて動作させるために、入れ子になったコードブロックを変換し、失敗パスへ到達するたびに `halt(conn)` を使用しています。ここでは `halt(conn)` の機能が不可欠です: 次のPlugを呼び出すべきではないことをPlugに伝えます。

要するに、入れ子になったコードのブロックをフラット化された一連のPlug変換に置き換えることで、同じ機能をより構成しやすく、明確で、再利用可能な方法で実現することができます。

Plugの詳細については、多くの組み込みPlugや機能を提供している [Plugプロジェクト](https://hexdocs.pm/plug) のドキュメントを参照してください。
