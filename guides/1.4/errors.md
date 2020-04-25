---
layout: 1.4/layout
version: 1.4
group: guides
title: カスタムエラー
nav_order: 14
hash: 04b49caba15318c4ed23b36888fdd893e1cd6abe
---
# カスタムエラー

Phoenixはアプリケーションのエラーを表示するための `ErrorView`, `lib/hello_web/views/error_view.ex` を提供しています。`Hello.ErrorView`のように、完全なモジュール名にはアプリケーションの名前が含まれます。

Phoenixはアプリケーション内の400または500のステータスレベルのエラーを検出すると、`ErrorView`の`render/2`関数を使用して適切なエラーテンプレートをレンダリングします。既存の `render/2` の節にマッチしないエラーは、`template_not_found/2` によって捕捉されます。

また、これらの関数の実装を好きなようにカスタマイズすることもできます。

以下は、`ErrorView`がどのようなものかを示しています。

```elixir
defmodule Hello.ErrorView do
  use Hello.Web, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
```

> 注意: 開発環境では、この動作はオーバーライドされます。その代わりに、とても有益なデバッグページが表示されます。動作中の `ErrorView` を見るためには、`config/dev.exs` で `debug_errors: false` を設定する必要があります。変更を有効にするにはサーバを再起動する必要があります。

```elixir
config :hello, HelloWeb.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  cache_static_lookup: false,
  watchers: [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin",
                    cd: Path.expand("../assets", __DIR__)]]
```

カスタムエラーページの詳細については、ビューガイドの[エラービュー](views.html#エラービュー)のセクションを参照してください。

## カスタム例外

Elixirには、カスタム例外を定義するための `defexception` というマクロがあります。例外は構造体として表現され、構造体はモジュール内で定義する必要があります。

カスタムエラーを作成するためには、新しいモジュールを定義する必要があります。通常、このモジュールの名前には "Error"が含まれます。このモジュールの中に、`defexception`で新しい例外を定義する必要があります。

また、モジュール内にモジュールを定義して、内部モジュールの名前空間を提供することもできます。

ここでは、これらの考え方のすべてを示している [Phoenix.Router](https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/router.ex) の例を紹介します。

```elixir
defmodule Phoenix.Router do
  defmodule NoRouteError do
    @moduledoc """
    Exception raised when no route is found.
    """
    defexception plug_status: 404, message: "no route found", conn: nil, router: nil

    def exception(opts) do
      conn   = Keyword.fetch!(opts, :conn)
      router = Keyword.fetch!(opts, :router)
      path   = "/" <> Enum.join(conn.path_info, "/")

      %NoRouteError{message: "no route found for #{conn.method} #{path} (#{inspect router})",
      conn: conn, router: router}
    end
  end
. . .
end
```

プラグは `Plug.Exception` というプロトコルを提供しており、特に例外構造体にステータスを追加するためのものです。

`Ecto.NoResultsError`に対して404のステータスを提供したい場合は、以下のように `Plug.Exception` プロトコルの実装を定義することで行うことができます。

```elixir
defimpl Plug.Exception, for: Ecto.NoResultsError do
  def status(_exception), do: 404
end
```

これは単なる例であることに注意してください。Phoenixは`Ecto.NoResultsError` に対して[既に実装済である](https://github.com/phoenixframework/phoenix_ecto/blob/master/lib/phoenix_ecto/plug.ex)ため、これを行う必要はありません。
