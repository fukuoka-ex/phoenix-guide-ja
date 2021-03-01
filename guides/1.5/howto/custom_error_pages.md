---
layout: 1.5/layout
version: 1.5
group: howto
title: カスタムエラーページ
nav_order: 1
hash: 42dbbfaf
---
# カスタムエラーページ

Phoenixには `ErrorView` というビューがあり、 `lib/hello_web/views/error_view.ex` にあります。この `ErrorView` の目的は、一般的な方法で一元的にエラーを処理することです。

## ErrorView

新しいアプリケーションの場合、ErrorViewは次のようになります。

```elixir
defmodule HelloWeb.ErrorView do
  use HelloWeb, :view

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

これに飛び込む前に、レンダリングされた `404 not found` メッセージがブラウザ上でどのように見えるか見てみましょう。開発環境では、Phoenixはデフォルトでエラーをデバッグし、非常に有益なデバッグページを表示します。しかし、ここで私たちが知りたいのは、アプリケーションが本番環境でどのようなページを表示するのかを見ることです。そのためには、`config/dev.exs` で `debug_errors: false` を設定する必要があります。

```elixir
use Mix.Config

config :hello, HelloWeb.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  . . .
```

設定ファイルを変更した後、この変更を有効にするにはサーバーを再起動する必要があります。サーバーを再起動した後、ローカルアプリケーションの [http://localhost:4000/such/a/wrong/path](http://localhost:4000/such/a/wrong/path) にアクセスして、何が得られるか見てみましょう。

さて、これはあまりエキサイティングではありません。マークアップもスタイリングもせずに、"Not Found" という文字列が表示されます。

最初の質問は、そのエラー文字列はどこから来ているのかということです。答えは `ErrorView` の中にあります。

```elixir
def template_not_found(template, _assigns) do
  Phoenix.Controller.status_message_from_template(template)
end
```

良いですね。`template_not_found/2` 関数はテンプレートと `assigns` マップを受け取りますが、`assigns` は無視します。`template_not_found/2` は、Phoenix.Viewがテンプレートをレンダリングしようとしてもテンプレートが見つからない場合に呼び出されます。

つまり、カスタムエラーページを提供するために、`HelloWeb.ErrorView` の中に適切な `render/2` 関数節を定義できます。

```elixir
def render("404.html", _assigns) do
  "Page Not Found"
end
```

しかし、私たちはもっと良いことができます。

Phoenixは `ErrorView` を生成してくれますが、`lib/hello_web/templates/error` ディレクトリを与えてくれません。それでは、ディレクトリを作成してみましょう。新しいディレクトリの中に `404.html.eex` というテンプレートを追加して、アプリケーションのレイアウトとユーザーへのメッセージを含む新しい `div` をマークアップしてみましょう。

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title>Welcome to Phoenix!</title>
    <link rel="stylesheet" href="/css/app.css">
  </head>

  <body>
    <div class="container">
      <div class="header">
        <ul class="nav nav-pills pull-right">
          <li><a href="https://hexdocs.pm/phoenix/overview.html">Get Started</a></li>
        </ul>
        <span class="logo"></span>
      </div>

      <div class="phx-hero">
        <p>Sorry, the page you are looking for does not exist.</p>
      </div>

      <div class="footer">
        <p><a href="https://phoenixframework.org">phoenixframework.org</a></p>
      </div>

    </div> <!-- /container -->
    <script src="/js/app.js"></script>
  </body>
</html>
```

さて、[http://localhost:4000/such/a/wrong/path](http://localhost:4000/such/a/wrong/path)に戻ると、より良いエラーページが表示されるはずです。エラーページをサイトの残りの部分と同じような見た目にしたいのに、アプリケーションのレイアウトで `404.html.eex` テンプレートをレンダリングしなかったことは注目に値します。これは循環エラーを避けるためです。たとえば、アプリケーションがレイアウトのエラーで失敗した場合はどうなるでしょうか？レイアウトを再度レンダリングしようとすると、別のエラーが発生します。そのため、理想的には、エラーテンプレートの依存関係やロジックの量を最小限に抑え、必要なものだけを共有したいと考えています。

## カスタムの例外

Elixirには、カスタム例外を定義するための `defexception` というマクロがあります。例外は構造体として表現され、構造体はモジュール内で定義する必要があります。

カスタム例外を作成するためには、新しいモジュールを定義する必要があります。通常、このモジュールの名前には "Error" が含まれています。このモジュールの中に、`defexception` で新しい例外を定義する必要があります。

```elixir
defmodule MyApp.SomethingNotFoundError do
  defexception [:message]
end
```

このように新しい例外を上げることができます。

```elixir
raise MyApp.SomethingNotFoundError, "oops"
```

デフォルトでは、PlugとPhoenixはすべての例外を500のエラーとして扱います。しかし、プラグは `Plug.Exception` というプロトコルを提供しています。このプロトコルでは、ステータスをカスタマイズしたり、例外構造体がデバッグエラーページに返すアクションを追加したりできます。

`MyApp.SomethingNotFoundError` に対して404のステータスを提供したい場合は、次のように `Plug.Exception` プロトコルの実装を定義することで行うことができます。

```elixir
defimpl Plug.Exception, for: MyApp.SomethingNotFoundError do
  def status(_exception), do: 404
  def actions(_exception), do: []
end
```

あるいは、例外構造体の中で `plug_status` フィールドを直接定義することもできます。

```elixir
defmodule MyApp.SomethingNotFoundError do
  defexception [:message, plug_status: 404]
end
```

しかし、アクション可能なエラーを提供する場合など、`Plug.Exception` プロトコルを手作業で実装しておくと便利な場合があります。

## アクション可能なエラー

例外アクションはエラーページからトリガーされる関数で、基本的には `label` と `handler` を定義したマップのリストです。

エラーページではボタンの集合として表示され、以下の形式で表示されます。の形式に従います: `[%{label: String.t(), handler: {module(), function :: atom(), args :: []}}]`.

`MyApp.SomethingNotFoundError` に対して何らかのアクションを返したい場合は、次のように `Plug.Exception` を実装します。

```elixir
defimpl Plug.Exception, for: MyApp.SomethingNotFoundError do
  def status(_exception), do: 404
  def actions(_exception), do: [%{
      label: "Run seeds",
      handler: {Code, :eval_file, "priv/repo/seeds.exs"}
    }]
end
```
