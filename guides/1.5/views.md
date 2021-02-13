---
layout: 1.5/layout
version: 1.5
group: guides
title: ビューとテンプレート
nav_order: 6
hash: 147308cf
---
# ビューとテンプレート

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: [リクエストのライフサイクルガイド](request_lifecycle.html)を理解していることを前提としています

Phoenix viewsの主な仕事は、ブラウザやAPIクライアントに送信されるレスポンスの本文をレンダリングすることです。ほとんどの場合、テンプレートを使用してレスポンスを作成しますが、手作業で作成することもできます。その方法を学びます。

## テンプレートのレンダリング

Phoenixでは、コントローラーからビュー、そしてそれらがレンダリングするテンプレートに至るまで、強力な命名規則を前提としています。`PageController` は、`lib/hello_web/templates/page` ディレクトリにあるテンプレートをレンダリングするために、`PageView` を必要とします。これらはすべてカスタマイズ可能ですが（詳細は `Phoenix.View` と `Phoenix.Template` を参照してください）、Phoenixの規約に従うことを推奨します。

新しく生成されたPhoenixアプリケーションには、`ErrorView`、`LayoutView`、`PageView` の3つのビューモジュールがあり、これらはすべて `lib/hello_web/views` ディレクトリにあります。

`LayoutView` を簡単に見てみましょう。

```elixir
defmodule HelloWeb.LayoutView do
  use HelloWeb, :view
end
```

これだけで十分シンプルです。`use HelloWeb, :view` という一行だけです。この行は上で見た `view/0` 関数を呼び出します。`view/0` はテンプレートのルートを変更できるだけでなく、`Phoenix.View` モジュールの `__using__` マクロを実行します。また、アプリケーションのビューモジュールが必要とするモジュールのインポートやエイリアスも処理します。

ビューで作成したインポートやエイリアスはすべて、テンプレートでも利用できます。これは、テンプレートがそれぞれのビュー内の関数に効果的にコンパイルされているからです。たとえば、ビュー内で関数を定義した場合、テンプレートから直接呼び出すことができます。実際に見てみましょう。

アプリケーションのレイアウトテンプレート `lib/hello_web/templates/layout/app.html.eex` を開き、この行を変更します。

```html
<title>Hello · Phoenix Framework</title>
```

`title/0` 関数を呼び出すには、このようにします。

```html
<title><%= title() %></title>
```

それでは、`LayoutView` に `title/0` 関数を追加してみましょう。

```elixir
defmodule HelloWeb.LayoutView do
  use HelloWeb, :view

  def title() do
    "Awesome New Title!"
  end
end
```

ホーム画面をリロードすると、新しいタイトルが表示されるはずです。テンプレートはビューの中でコンパイルされているので、単に `title()` としてビュー関数を呼び出すことができますが、そうでなければ `HelloWeb.LayoutView.title()` と入力しなければなりません。

Elixirテンプレートでは、`EEx` として知られるEmbedded Elixirを使用しています。Elixirの式を実行するには、`<%= 式 %>` を使用します。式の結果はテンプレートに補間されます。Elixir式はほとんどのものを使うことができます。たとえば、条件式を持つには、以下のようにします。

```html
<%= if some_condition? do %>
  <p>Some condition is true for user: <%= @user.name %></p>
<% else %>
  <p>Some condition is false for user: <%= @user.name %></p>
<% end %>
```

ループも可能です。

```html
<table>
  <tr>
    <th>Number</th>
    <th>Power</th>
  </tr>
<%= for number <- 1..10 do %>
  <tr>
    <td><%= number %></td>
    <td><%= number * number %></td>
  </tr>
<% end %>
</table>
```

最後に、私たちのテンプレートは常にElixirのコードにコンパイルされています。これについて詳しく見ていきましょう。

### テンプレートのコンパイルを理解する

テンプレートをビューにコンパイルする際には、単純に `render` 関数としてコンパイルされます。

このことを証明するには、`lib/hello_web/views/page_view.ex` の `PageView` モジュールに次の関数を一時的に追加します。

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view

  def render("index.html", assigns) do
    "rendering with assigns #{inspect Map.keys(assigns)}"
  end
end
```

さて、`mix phx.server` でサーバを起動して `http://localhost:4000` にアクセスすると、メインテンプレートページの代わりにレイアウトヘッダーの下に以下のテキストが表示されるはずです。

```console
rendering with assigns [:conn, :view_module, :view_template]
```

独自の `render` 句を定義することで、テンプレートよりも優先度が高くなります。新たに追加した句を単に削除することで、テンプレートはまだ存在していることを確認できます。

非常にすっきりしていますよね？コンパイル時に、Phoenixはすべての `*.html.eex` テンプレートをプリコンパイルし、それぞれのビューモジュール上で `render/2` 関数節に変換します。実行時には、すべてのテンプレートはすでにメモリにロードされています。ディスクの読み込み、複雑なファイルのキャッシング、テンプレートエンジンの計算は必要ありません。

### テンプレートを手動でレンダリングする

これまでのところ、Phoenixがすべてを配置し、ビューをレンダリングしてくれています。しかし、ビューを直接レンダリングすることもできます。

新しいテンプレート `lib/hello_web/templates/page/test.html.eex` を作成して遊んでみましょう。

```html
This is the message: <%= @message %>
```

これはコントローラーのどのアクションにも対応していません。これを `iex` セッションで実行してみましょう。プロジェクトのルートで `iex -S mix` を実行し、テンプレートを明示的にレンダリングします。

```elixir
iex(1)> Phoenix.View.render(HelloWeb.PageView, "test.html", message: "Hello from IEx!")
{:safe, ["This is the message: ", "Hello from IEx!"]}
```

見ての通り、テストテンプレートを担当する個々のビューとテストテンプレートの名前、そして渡したい変数を表すマップを指定して `render/3` を呼び出しています。戻り値は、アトム `:safe` で始まるタプルと、補間されたテンプレートの結果のioリストです。ここでの "セーフ "は、XSSインジェクション攻撃を避けるためにレンダリングされたテンプレートの内容をPhoenixがエスケープしたことを意味します。

それでは、HTMLのエスケープをテストしてみましょう。

```elixir
iex(2)> Phoenix.View.render(HelloWeb.PageView, "test.html", message: "<script>badThings();</script>")
{:safe, ["This is the message: ", "&lt;script&gt;badThings();&lt;/script&gt;"]}
```

タプル全体を使わずにレンダリングされた文字列だけが必要な場合は、`render_to_string/3` を使うことができます。

```elixir
iex(5)> Phoenix.View.render_to_string(HelloWeb.PageView, "test.html", message: "Hello from IEx!")
"This is the message: Hello from IEx!"
```

## ビューとテンプレートを共有する

これで `Phoenix.View.render/3` を使いこなせるようになったので、他のビューやテンプレートの内部からビューやテンプレートを共有する準備ができました。

たとえば、レイアウトの内部から "test.html" テンプレートをレンダリングしたい場合、レイアウトから直接 `render/3` を呼び出すことができます。

```html
<%= Phoenix.View.render(HelloWeb.PageView, "test.html", message: "Hello from layout!") %>
```

ウェルカムページにアクセスすると、レイアウトからのメッセージが表示されるはずです。

`Phoenix.View` はテンプレートに自動的にインポートされるので、`Phoenix.View` モジュール名を省略して、単に `render(....)` を直接呼び出すこともできます。

```html
<%= render(HelloWeb.PageView, "test.html", message: "Hello from layout!") %>
```

同じビュー内でテンプレートをレンダリングしたい場合は、ビュー名を省略して `render("test.html", message: "Hello from sibling template!")` を呼び出すだけでも構いません。たとえば、`lib/hello_web/templates/page/index.html.eex` を開いて、先頭に以下のように追加します。

```html
<%= render("test.html", message: "Hello from sibling template!") %>
```

さて、ウェルカムページにアクセスすると、テンプレートの結果も表示されています。

## レイアウト

レイアウトは単なるテンプレートです。他のテンプレートと同じようにビューを持っています。新しく生成されたアプリでは、`lib/hello_web/views/layout_view.ex` となります。レンダリングされたビューから得られる文字列がどのようにレイアウト内に行き着くのか不思議に思うかもしれません。これはいい質問ですね。`lib/hello_web/templates/layout/app.html.ex` を見てみると、`<body>` のちょうど真ん中あたりにこのような記述があります。

```html
<%= @inner_content %>
```

言い換えれば、内部テンプレートは `@inner_content` 代入に配置されます。また、`@view_module` と `@view_template` を参照することで、どのモジュールとテンプレートが内部コンテンツのレンダリングに使われたかを知ることができます。

## JSONをレンダリングする

ビューの仕事はHTMLテンプレートをレンダリングするだけではありません。ビューの目的はデータの表示です。データの袋を与えられた場合、ビューの目的は、HTML、JSON、CSV、その他のフォーマットを与えられた場合に、意味のある方法でそのデータを表示することです。今日の多くのウェブアプリは、リモートクライアントにJSONを返しますが、Phoenix ViewsはJSONレンダリングに**最適**です。

PhoenixはJSONをエンコードするために[Jason](https://github.com/michalmuskala/jason)を使用しているので、私たちのビューで必要なのはリストやマップとして応答したいデータをフォーマットするだけで、あとはPhoenixが処理してくれます。

コントローラーから直接JSONを返してビューをスキップすることも可能ですが、Phoenix Viewsはそのためのより構造化されたアプローチを提供しています。ここでは `PageController` を例にとり、HTMLの代わりに静的なページマップをJSONで返した場合にどのようになるかを見てみましょう。

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def show(conn, _params) do
    page = %{title: "foo"}

    render(conn, "show.json", page: page)
  end

  def index(conn, _params) do
    pages = [%{title: "foo"}, %{title: "bar"}]

    render(conn, "index.json", pages: pages)
  end
end
```

ここでは、`show/2` と `index/2` アクションが静的なページデータを返しています。テンプレート名として `render/3` に `"show.html"` を渡す代わりに、`"show.json"` を渡しています。このようにして、異なるファイルタイプでパターンマッチを行うことで、HTMLとJSONのレンダリングを担当するビューを持つことができます。

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view

  def render("index.json", %{pages: pages}) do
    %{data: render_many(pages, HelloWeb.PageView, "page.json")}
  end

  def render("show.json", %{page: page}) do
    %{data: render_one(page, HelloWeb.PageView, "page.json")}
  end

  def render("page.json", %{page: page}) do
    %{title: page.title}
  end
end
```

ビューでは、`render/2` 関数が `"index.json"`、`"show.json"`、`"page.json"` でパターンマッチしているのがわかります。index.json "と "show.json "はコントローラーから直接リクエストされたものです。これらはコントローラーから送られてきたassignにマッチします。`index.json"` はこのようなJSONを返します。

```javascript
{
  "data": [
    {
     "title": "foo"
    },
    {
     "title": "bar"
    },
 ]
}
```

そして、`render/2` は `"show.json"` にマッチします。

```javascript
{
  "data": {
    "title": "foo"
  }
}
```

これは、"index.json" と"show.json" の両方が、内部の "page.json" を利用して自身の関数を構築しているからです。

`render_many/3` 関数は、応答したいデータ（`pages`）とビュー、そしてビュー上で定義された `render/2` 関数にパターンマッチする文字列を受け取ります。`pages` の各項目をマップして、`PageView.render("page.json", %{page: page})` を呼び出します。これに続いて `render_one/3` も同じシグネチャで、最終的には `render/2` にマッチする `page.json` を使って各 `page` がどのように見えるかを指定します。

このようにしてビューを構築すると、合成できるようになるので便利です。たとえば、`Page` が `Author` と `has_many` の関係を持っていて、リクエストによっては `author` のデータを `page` と一緒に送り返したい場合を想像してみてください。これは新しい `render/2` で簡単に実現できます。

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view
  alias HelloWeb.AuthorView

  def render("page_with_authors.json", %{page: page}) do
    %{title: page.title,
      authors: render_many(page.authors, AuthorView, "author.json")}
  end

  def render("page.json", %{page: page}) do
    %{title: page.title}
  end
end
```

assignで使用される名前はビューから決定されます。たとえば、`PageView` は `%{page: page}` を、`AuthorView` は `%{author: author}` を使用します。これは `as` オプションで上書きできます。ここで、著者ビューでは `%{author: author}` の代わりに `%{writer: writer}` を使うと仮定してみましょう。

```elixir
def render("page_with_authors.json", %{page: page}) do
  %{title: page.title,
    authors: render_many(page.authors, AuthorView, "author.json", as: :writer)}
end
```

## エラーページ

Phoenixには `ErrorView` というビューがあり、 `lib/hello_web/views/error_view.ex` にあります。この `ErrorView` の目的は、一般的な方法でエラーを一元的に処理することです。 このガイドで作成したビューと同様に、エラービューはHTMLとJSONの両方のレスポンスを返すことができます。詳細は [カスタムエラーページのハウツー](custom_error_pages.html) を参照してください。