---
layout: default
group: guides
title: プラグ
nav_order: 4
hash: 0909faec38227c68a703711753e6413a64ae155a
---

# プラグ

プラグはPhoenixのHTTPレイヤーの中心にあり、Phoenixはプラグを中心に置いています。コネクションライフサイクルのすべてのステップでプラグを使用しており、エンドポイント、ルーター、コントローラーなどのPhoenixのコアコンポーネントは、内部的にはすべてプラグです。プラグの特徴を見てみましょう。

[プラグ](https://github.com/elixir-lang/plug)は、Webアプリケーションの間にある合成可能なモジュールのための仕様です。また、異なるウェブサーバの接続アダプターのための抽象化レイヤーでもあります。プラグの基本的な考え方は、我々が操作する「コネクション」という概念を統一することです。これは、ミドルウェアスタックの中でリクエストとレスポンスが分離されているRackなどの他のHTTPミドルウェア層とは異なります。

もっとも単純なレベルでは、プラグの仕様には2つの特徴があります。*関数プラグ*と*モジュールプラグ*です。

## 関数プラグ
プラグとして動作するためには、関数は単にコネクション構造体（`%Plug.Conn{}`）とオプションを受け取る必要があります。また、コネクション構造体を返す必要があります。これらの基準を満たす関数であれば、どのようにしても動作します。以下に例を示します。

```elixir
def put_headers(conn, key_values) do
  Enum.reduce key_values, conn, fn {k, v}, conn ->
    Plug.Conn.put_resp_header(conn, to_string(k), v)
  end
end
```

簡単ですよね？

これを使ってPhoenixでのコネクションで一連の変換を構成します。

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  plug :put_headers, %{content_encoding: "gzip", cache_control: "max-age=3600"}
  plug :put_layout, "bare.html"

  ...
end
```

プラグの規約に従うことで、`put_headers/2`、`put_layout/2`、さらには`action/2`はアプリケーションのリクエストを明示的に変換します。これで終わりではありません。プラグの設計がどれほど効果的かを実際に見るために、一連の条件をチェックして、条件が失敗した場合にリダイレクトするか停止する必要があるシナリオを想像してみましょう。プラグがなければ、次のようなシナリオになるでしょう。

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  def show(conn, params) do
    case authenticate(conn) do
      {:ok, user} ->
        case find_message(params["id"]) do
          nil ->
            conn |> put_flash(:info, "That message wasn't found") |> redirect(to: "/")
          message ->
            case authorize_message(conn, params["id"]) do
              :ok ->
                render(conn, :show, page: find_message(params["id"]))
              :error ->
                conn |> put_flash(:info, "You can't access that page") |> redirect(to: "/")
            end
        end
      :error ->
        conn |> put_flash(:info, "You must be logged in") |> redirect(to: "/")
    end
  end
end
```

認証と認可のわずか数ステップで、複雑な入れ子と重複を必要とすることにお気づきでしょうか？これをいくつかのプラグで改善してみましょう。

```elixir
defmodule HelloWeb.MessageController do
  use HelloWeb, :controller

  plug :authenticate
  plug :fetch_message
  plug :authorize_message

  def show(conn, params) do
    render(conn, :show, page: find_message(params["id"]))
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

入れ子になっていたコードのブロックを、フラットな一連のプラグに置き換えることで、同じ機能を、より構成しやすく、明確で、再利用可能な方法で実現することができるようになりました。

次に、他の特徴を持つプラグであるモジュールプラグを見てみましょう。

## モジュールプラグ

モジュールプラグは、モジュール内のコネクション変換を定義するためのプラグの別のタイプです。モジュールは2つの関数を実装するだけです。

- `init/1`: `call/2`に渡される引数やオプションを初期化します。
- `call/2`: コネクション変換を実行します。`call/2`は先ほど見た関数プラグです。

これを実際に見るために、`:locale`のキーと値をコネクションのassignに設定するモジュールプラグを書いてみましょう。

```elixir
defmodule HelloWeb.Plugs.Locale do
  import Plug.Conn

  @locales ["en", "fr", "de"]

  def init(default), do: default

  def call(%Plug.Conn{params: %{"locale" => loc}} = conn, _default) when loc in @locales do
    assign(conn, :locale, loc)
  end
  def call(conn, default), do: assign(conn, :locale, default)
end

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

このモジュールのプラグインをbrowserのパイプラインに追加するには、`plug HelloWeb.Plugs.Locale, "en"`を使用します。`init/1`コールバックでは、パラメーターにロケールがない場合に使用するデフォルトのロケールを渡します。また、パターンマッチングを使用して複数の`call/2`関数を定義してパラメーターのロケールを検証し、マッチしない場合は"en"にフォールバックします。

プラグはこれだけです。Phoenixは、スタック全体で構成可能な変換を行うプラグデザインを採用しています。これははじめての経験に過ぎません。これをプラグに入れてもいいかな？と自問自答すれば、たいていの場合、答えは"Yes！"です。

