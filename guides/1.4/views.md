---
layout: default
group: guides
title: ビュー
nav_order: 7
hash: 8d130727f9d6b92ae2eab5990fa6943773facfb5
---

# ビュー

Phoenixビューには主に2つの仕事があります。まず第一に、テンプレートをレンダリングします（これにはレイアウトも含まれます）。レンダリングに関わるコア関数である`render/3`は、Phoenix自体の`Phoenix.View`モジュールで定義されています。ビューは、生データを取得してテンプレートで使いやすくする関数も提供しています。デコレータやファサードパターンに慣れている人なら、これと似たようなものです。 

## テンプレートのレンダリング

Phoenixでは、コントローラーからビュー、そしてそれらがレンダリングするテンプレートに至るまで、強力な命名規則を前提としています。`PageController`は、`lib/hello_web/templates/page`ディレクトリにあるテンプレートをレンダリングするために、`PageView`を必要とします。必要であれば、Phoenixがテンプレートのルートとみなすディレクトリを変更可能です。Phoenixは `lib/hello_web.ex` で定義されている `HelloWeb` モジュールの中に `view/0` 関数を提供しています。`view/0`の最初の行では、`:root`キーに代入された値を変更することで、ルートディレクトリを変更できます。

新しく生成されたPhoenixアプリケーションには、`ErrorView`、`LayoutView`、`PageView`の3つのビューモジュールがあり、これらはすべて`lib/hello_web/views`ディレクトリにあります。

`LayoutView`を簡単に見てみましょう。

```elixir
defmodule HelloWeb.LayoutView do
  use HelloWeb, :view
end
```

これだけで十分シンプルです。`use HelloWeb, :view`という一行だけです。この行は上で見た `view/0` 関数を呼び出します。`view/0` はテンプレートのルートを変更できるだけでなく、`Phoenix.View` モジュールの `__using__` マクロを実行します。また、アプリケーションのビューモジュールが必要とするモジュールのインポートやエイリアスも処理します。

このガイドの最初の方で、ビューはテンプレートで利用するための関数を配置する場所であることを述べました。それでは、少し実験してみましょう。

アプリケーションのレイアウトテンプレート `lib/hello_web/templates/layout/app.html.eex` を開いて、この行を変更してみましょう。

```html
<title>Hello · Phoenix Framework</title>
```

`title/0` 関数を呼び出すには、このようにします。


```html
<title><%= title() %></title>
```

それでは、`LayoutView`に`title/0`関数を追加してみましょう。

```elixir
defmodule HelloWeb.LayoutView do
  use HelloWeb, :view

  def title do
    "Awesome New Title!"
  end
end
```

「ようこそフェニックスへ」のページをリロードすると、新しいタイトルが表示されるはずです。

`<%=`と`%>`はElixirの[EEx](https://hexdocs.pm/eex/EEx.html)プロジェクトのものです。これらはテンプレート内で実行可能なElixirのコードを囲んでいます。`=` はEExに結果を表示するように指示します。もし`=`がない場合でもEExはコードを実行しますが、出力はありません。この例では、`LayoutView`から`title/0`関数を呼び出し、出力をタイトルタグに出力しています。

`LayoutView`が実際にレンダリングを行うので、`title/0`を`HelloWeb.LayoutView`で完全に修飾する必要はありません。実際、Phoenixの"テンプレート"は、ビューモジュールの関数定義にすぎません。これを試すには、`lib/hello_web/templates/page/index.html.eex`ファイルを一時的に削除して、`lib/hello_web/views/page_view.ex`の中の`PageView`モジュールにこの関数を追加します。

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view

  def render("index.html", assigns) do
    "rendering with assigns #{inspect Map.keys(assigns)}"
  end
end
```

さて、`mix phx.server`でサーバを起動して`http://localhost:4000`にアクセスすると、メインテンプレートページの代わりにレイアウトヘッダの下に以下のテキストが表示されるはずです。

```console
rendering with assigns [:conn, :view_module, :view_template]
```

とてもすっきりしていますよね？コンパイル時に、Phoenixはすべての`*.html.eex`テンプレートをプリコンパイルし、それぞれのビューモジュール上で`render/2`関数定義に変換します。実行時には、すべてのテンプレートはすでにメモリにロードされています。ディスクの読み込み、複雑なファイルのキャッシング、テンプレートエンジンの計算などはありません。これが `LayoutView` の中で `title/0` のような関数を定義でき、レイアウトの `app.html.eex` の中ですぐに利用できる理由でもあります - `title/0` への呼び出しはローカル関数の呼び出しに過ぎません。

`use HelloWeb, :view`をuseすると、他にも便利なことがあります。`view/0`は`HelloWeb.Router.Helpers`を`Routes`としてエイリアスしているので（`lib/hello_web.ex`を参照してください）、テンプレートで `Routes.*_path`を利用してこれらのヘルパーを簡単に呼び出すことができます。それでは、Welcome to Phoenixページのテンプレートを変更して、どのように動作するか見てみましょう。

`lib/hello_web/templates/page/index.html.eex`を開いて、次の一節を探してみましょう。

```html
<section class="phx-hero">
  <h1><%= gettext "Welcome to %{name}!", name: "Phoenix" %></h1>
  <p>A productive web framework that<br/>does not compromise speed or maintainability.</p>
</section>
```

そして、同じページに戻るリンクを持つ行を追加してみましょう。（目的はテンプレート内でパスヘルパーがどのように反応するかを見ることであり、機能を追加することではありません）。

```html
<section class="phx-hero">
  <h1><%= gettext "Welcome to %{name}!", name: "Phoenix" %></h1>
  <p>A productive web framework that<br/>does not compromise speed or maintainability.</p>
  <p><a href="<%= Routes.page_path(@conn, :index) %>">Link back to this page</a></p>
</section>
```

あとはページをリロードしてソースを表示して、何があるのかを確認するだけです。

```html
<a href="/">Link back to this page</a>
```

素晴らしい、セットされたエイリアスを利用するだけで、`Routes.page_path/2`は期待通り`/`に評価されました。

ビュー、コントローラー、テンプレートの外でパスヘルパーにアクセスする必要がある場合は、`HelloWeb.Router.Helperers.page_path(@conn, :index)`のような完全な修飾名で呼び出すか、使用したいモジュール内で`alias HelloWeb.Router.Helperers, as.Routes`を定義してから、`Routes.page_path(@conn, :index)`のように呼び出します。

### ビューの詳細

どうやってビューがテンプレートと密接に動作するのか不思議に思うかもしれません。

`Phoenix.View`モジュールは`__using__/1`マクロの`use Phoenix.Template`行を使ってテンプレートの振る舞いにアクセスしています。`Phoenix.Template`には、テンプレートの検索や名前やパスの抽出など、テンプレートを操作するための便利なメソッドがたくさんあります。

Phoenixが生成してくれるビューの1つである`lib/hello_web/views/page_view.ex`を使って少し実験してみましょう。これに`message/0`関数を追加すると、次のようになります。

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view

  def message do
    "Hello from the view!"
  end
end
```

それでは、新しいテンプレート`lib/hello_web/templates/page/test.html.eex`を作成して遊んでみましょう。

```html
This is the message: <%= message() %>
```

これはコントローラー内のアクションには対応していませんが、`iex`セッションで実行できます。プロジェクトのルートで `iex -S mix` を実行し、テンプレートを明示的にレンダリングします。

```elixir
iex(1)> Phoenix.View.render(HelloWeb.PageView, "test.html", %{})
  {:safe, [["" | "This is the message: "] | "Hello from the view!"]}
```

見ての通り、testテンプレートを担当する個々のビュー、testテンプレートの名前、そして渡したいデータを表す空のマップを指定して`render/3`を呼び出しています。戻り値は、`:safe`アトムで始まるタプルと、補間されたテンプレートの結果のioリストです。ここでの"Safe"は、Phoenixがレンダリングされたテンプレートの内容をエスケープしたことを意味します。Phoenixは独自の`Phoenix.HTML.Safe`プロトコルを定義しており、アトム、ビットストリング、リスト、整数、浮動小数点数、タプルなどの実装があり、テンプレートが文字列へレンダリングされる際にエスケープ処理してくれます。

もし、`render/3`の第3引数にいくつかのキー値のペアを代入するとどうなるでしょうか？それを知るためには、テンプレートを少し変更する必要があります。

```html
I came from assigns: <%= @message %>
This is the message: <%= message() %>
```

上の行の`@`に注目してください。関数呼び出しを変更すると、`PageView`モジュールを再コンパイルした後に、異なるレンダリングが表示されるようになります。

```elixir
iex(2)> r HelloWeb.PageView
warning: redefining module HelloWeb.PageView (current version loaded from _build/dev/lib/hello/ebin/Elixir.HelloWeb.PageView.beam)
  lib/hello_web/views/page_view.ex:1

{:reloaded, HelloWeb.PageView, [HelloWeb.PageView]}

iex(3)> Phoenix.View.render(HelloWeb.PageView, "test.html", message: "Assigns has an @.")
{:safe,
  [[[["" | "I came from assigns: "] | "Assigns has an @."] |
  "\nThis is the message: "] | "Hello from the view!"]}
 ```

試しにHTMLエスケープを試してみましょう。

```elixir
iex(4)> Phoenix.View.render(HelloWeb.PageView, "test.html", message: "<script>badThings();</script>")
{:safe,
  [[[["" | "I came from assigns: "] |
     "&lt;script&gt;badThings();&lt;/script&gt;"] |
    "\nThis is the message: "] | "Hello from the view!"]}
```

タプル全体を抜きにしてレンダリングされた文字列だけが必要な場合は、`render_to_iodata/3`を使うことができます。

```elixir
iex(5)> Phoenix.View.render_to_iodata(HelloWeb.PageView, "test.html", message: "Assigns has an @.")
[[[["" | "I came from assigns: "] | "Assigns has an @."] |
  "\nThis is the message: "] | "Hello from the view!"]
```

### レイアウトについて

レイアウトは単なるテンプレートです。他のテンプレートと同じようにビューを持っています。新しく生成されたアプリでは、`lib/hello_web/views/layout_view.ex`となります。レンダリングされたビューから得られる文字列がどのようにレイアウト内で終わるのか不思議に思うかもしれません。それはいい質問ですね！ `lib/hello_web/templates/layout/app.html.ex`を見てみると、`<body>`のちょうど真ん中あたりにこのような記述があります。

```html
<%= render(@view_module, @view_template, assigns) %>
```

ここに、コントローラーからのビューモジュールとそのテンプレートが文字列にレンダリングされてレイアウトに配置されます。

## エラービュー

Phoenixには`ErrorView`というビューがあり、`lib/hello_web/views/error_view.ex`にあります。この `ErrorView` の目的は、もっとも一般的なエラーである`404 not found`と`500 internal error`の2つのエラーを一般的な方法で一箇所から処理することです。どのように見えるか見てみましょう。

```elixir
defmodule HelloWeb.ErrorView do
  use HelloWeb, :view

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    "Server internal error"
  end
end
```

その前に、レンダリングされた`404 not found`メッセージがブラウザ上でどのように見えるか見てみましょう。開発環境では、Phoenixはデフォルトでエラーをデバッグし、非常に有益なデバッグページを表示します。しかし、ここで私たちが知りたいのは、アプリケーションが本番環境でどのようなページを表示するのかを見ることです。そのためには、`config/dev.exs`で`debug_errors: false`を設定する必要があります。

```elixir
use Mix.Config

config :hello, HelloWeb.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  . . .
```

設定ファイルを変更した後、この変更を有効にするにはサーバを再起動する必要があります。サーバーを再起動した後、ローカルアプリケーションの[http://localhost:4000/such/a/wrong/path](http://localhost:4000/such/a/wrong/path)にアクセスして、何が表示されるか見てみましょう。

さて、これはあまりエキサイティングではありません。「ページが見つかりませんでした」というむき出しの文字列が表示され、何のマークアップもスタイリングもされていません。

これをより面白いエラーページにするために、ビューについてすでに知っていることを使ってみましょう。

最初の質問は、このエラー文字列はどこから来ているのか？ということです。答えは `ErrorView` の中にあります。

```elixir
def render("404.html", _assigns) do
  "Page not found"
end
```

良いですね。`render/2`関数はテンプレートと`assigns`マップを受け取りますが、`assigns`マップは無視しています。この`render/2`関数はどこから呼び出されているのでしょうか？答えは`Phoenix.Endpoint.RenderErrors`モジュールで定義されている`render/5`関数です。このモジュールの目的は、エラーをキャッチしてビューでレンダリングすること、今回の場合は`HelloWeb.ErrorView`でレンダリングすることです。ここまでの経緯が理解できたので、より良いエラーページを作ってみましょう。Phoenixは`ErrorView`を生成してくれますが、`lib/hello_web/templates/error`ディレクトリを与えてくれません。それでは、作成してみましょう。新しいディレクトリの中に `404.html.eex` というテンプレートを追加して、アプリケーションのレイアウトとユーザーへのメッセージを含む新しい`div`をマークアップしてみましょう。

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
        <p><a href="http://phoenixframework.org">phoenixframework.org</a></p>
      </div>

    </div> <!-- /container -->
    <script src="/js/app.js"></script>
  </body>
</html>
```

これで、`iex`セッションでレンダリングを実験していたときに見た`render/2`関数を使用できるようになりました。Phoenixは `404.html.eex` テンプレートを`render("404.html", assigns)`関数としてプリコンパイルすることがわかっているので、この関数定義をErrorViewから削除することができます。

```diff
- def render("404.html", _assigns) do
-   "Page not found"
- end
```

[http://localhost:4000/such/a/wrong/path](http://localhost:4000/such/a/wrong/path)に戻ると、より良いエラーページを見ることができるはずです。エラーページをサイトの残りの部分と同じような見た目にしたいのに、アプリケーションのレイアウトで`404.html.eex`テンプレートをレンダリングしなかったことは注目に値します。主な理由は、エラーをグローバルに処理している間にエッジケースの問題に遭遇しやすいからです。アプリケーションレイアウトと`404.html.eex`テンプレート間の重複を最小限にしたい場合は、ヘッダーとフッターに共有テンプレートを実装することができます。詳細は[テンプレートガイド](templates.html)を参照してください。もちろん、`ErrorView`の`def render("500.html", _assigns) do`関数を使っても同じことができます。また、`ErrorView`の`render/2`句に渡された`assigns`マップを捨てずに使用することで、テンプレートに多くの情報を表示することができます。

## JSONのレンダリング

ビューの仕事はHTMLテンプレートをレンダリングするだけではありません。ビューの目的はデータの表示です。データがどっさりと与えられたとき、ビューの目的は、HTML、JSON、CSV、その他のフォーマットにより意味付けされた方法でそのデータを表示することです。今日の多くのWebアプリケーションは、JSONをリモートクライアントに返しますが、PhoenixのビューはJSONレンダリングに最適です。Phoenixは[Jason](https://github.com/michalmuskala/jason)を使用してマップをJSONにエンコードするので、ビューで必要なのは、応答したいデータをマップとしてフォーマットするだけで、あとはPhoenixが行います。コントローラーから直接JSONを返して、Viewをスキップして応答することも可能です。しかし、コントローラーはリクエストを受信してデータを取得して送信する責任があると考えると、データ操作やフォーマットはこれらの責任には該当しません。ビューは、データをフォーマットしたり操作したりするモジュールの責務を提供してくれます。ここでは`PageController`を例にとり、HTMLの代わりに静的なページマップをJSONで返したときにどのように見えるかを見てみましょう。

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

ここでは、`show/2`と`index/2`アクションが静的なページデータを返しています。テンプレート名として`render/3`に`"show.html"`を渡す代わりに、`"show.json"`を渡します。このようにして、異なるファイルタイプでパターンマッチを行うことで、HTMLとJSONのレンダリングを担当するビューを持つことができます。

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

ビューでは、`render/2`関数が`"index.json"`,`"show.json"`,`"page.json"`でパターンマッチしています。コントローラーの`show/2`関数内の`render(conn, "show.json", page: page)`は、ビューの`render/2`関数内のマッチする名前と拡張子でパターンマッチを行います。つまり、`render(conn, "index.json", pages: pages)`は`render("index.json", %{pages: pages})`を呼び出します。`render_many/3`関数は、応答したいデータ(`pages`)、`View`、そして`View`で定義された`render/2`関数でパターンマッチする文字列を受け取ります。`pages`の各要素をマップし、ファイルの文字列にマッチした要素を`View`の`render/2`関数に渡します。これに続いて`render_one/3`も同じシグネチャで、最終的には `render/2` にマッチする `page.json` を使って各 `page` がどのように見えるかを指定します。マッチする `"index.json"` は、期待通りのJSONで応答します。

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

そして、`"show.json"`にマッチする`render/2`関数の結果は次のようになります:


```javascript
{
  "data": {
    "title": "foo"
  }
}
```

このようにビューを構築して、それらを合成できるようにしておくと便利です。たとえば、`Page`が`Author`と`has_many`の関係を持っていて、リクエストによっては`author`のデータを`page`と一緒に送り返したい場合を想像してみてください。これは新しい`render/2`で簡単に実現できます:

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

assigns（訳注: render/2の第2引数）で使用される名前はビューから決定されます。たとえば、`PageView`は`%{page: page}`を、`AuthorView`は`%{author: author}`を使用します。これは`as`オプションで上書きすることができます。ここで、著者ビューでは `%{author: author}` の代わりに `%{writer: writer}` を使うと仮定してみましょう。

```elixir
def render("page_with_authors.json", %{page: page}) do
  %{title: page.title,
    authors: render_many(page.authors, AuthorView, "author.json", as: :writer)}
end
```
