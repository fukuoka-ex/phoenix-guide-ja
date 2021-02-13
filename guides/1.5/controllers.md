---
layout: 1.5/layout
version: 1.5
group: guides
title: コントローラー
nav_order: 5
hash: a6b444e7
---
# コントローラー

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: [リクエストのライフサイクルガイド](request_lifecycle.html)を理解していることを前提としています

Phoenixコントローラーは、中間モジュールとして機能します。アクションと呼ばれる機能は、HTTPリクエストに応答してルーターから呼び出されます。アクションは必要なデータをすべて収集し、ビューレイヤーを呼び出してテンプレートをレンダリングしたり、JSONレスポンスを返したりする前に、必要なすべてのステップを実行します。

Phoenixのコントローラーもまた、プラグパッケージをベースにしており、それ自体がプラグです。コントローラーは、アクションで必要なことをほとんどすべて行うための機能を提供します。Phoenixコントローラーが提供していないものを探していることに気がついた場合は、プラグ自体の中に探しているものがあるかもしれません。詳細については、[プラグガイド](plug.html)または[プラグのドキュメント](https://hexdocs.pm/plug/)を参照してください。

新しく生成されたPhoenixアプリには、単一のコントローラーである`PageController`があり、`lib/hello_web/controllers/page_controller.ex`にあります。

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
```

モジュール定義の下の最初の行では、`HelloWeb`モジュールの`__using__/1`マクロを呼び出しており、いくつかの便利なモジュールをインポートしています。

`PageController`は、Phoenixがルーターで定義したデフォルトルートに関連付けられたPhoenixのウェルカムページを表示するための`index`アクションを提供します。

## アクション

コントローラーのアクションはただの関数です。Elixirの命名規則に従う限り、好きな名前をつけることができます。唯一満たさなければならない要件は、アクション名がルーターで定義されたルートと一致することです。

たとえば、`lib/hello_web/router.ex`では、新しいアプリでPhoenixが与えてくれるデフォルトのルートのアクション名をindexから変更できます。

```elixir
get "/", PageController, :index
```

これを:testに変更できます。

```elixir
get "/", PageController, :test
```

同様に `PageController`のアクション名を`test`に変更すれば、ウェルカムページは以前と同じように読み込まれます。

```elixir
defmodule HelloWeb.PageController do
  ...

  def test(conn, _params) do
    render(conn, "index.html")
  end
end
```
アクションには好きな名前をつけることができますが、可能な限り従うべきアクション名の規約があります。[ルーティング](routing.html)で説明しましたが、ここでも簡単に見てみましょう。

- index - 与えられたリソースタイプの全アイテムのリストを表示します
- show - IDを元に個々のアイテムを表示します
- new - 新しいアイテムを作成するためのフォームをレンダリングします
- create - 新しいアイテムのパラメーターを受け取り、それをデータストアに保存します
- edit - 個々のアイテムをIDで取得し、編集用のフォームに表示します
- update - 編集されたアイテムのパラメーターを受け取り、データストアに保存します
- delete - 削除するアイテムのIDを受け取り、データストアから削除します

これらのアクションにはそれぞれ2つのパラメーターが必要で、これはPhoenixが裏で提供するものです。

最初のパラメーターは常に`conn`で、ホスト、パス要素、ポート、クエリ文字列などのリクエストに関する情報を保持する構造体です。`conn`は、Elixirのプラグミドルウェアフレームワークを介してPhoenixに提供されます。`conn`の詳細については [プラグのドキュメント](https://hexdocs.pm/plug/Plug.Conn.html)を参照してください。

2番目のパラメーターは`params`です。驚くことではありませんが、これはHTTPリクエストで渡されたすべてのパラメーターを保持するマップです。レンダリングに渡すことができるシンプルなパッケージのデータを提供するために、関数のシグネチャでparamsとパターンマッチするのは良い習慣です。これは、`lib/hello_web/controllers/hello_controller.ex`の`show`ルートにmessengerパラメーターを追加したときに、[リクエストライフサイクルガイド](request_lifecycle.html) で見ました。

```elixir
defmodule HelloWeb.HelloController do
  ...

  def show(conn, %{"messenger" => messenger}) do
    render(conn, "show.html", messenger: messenger)
  end
end
```

いくつかのケース、たとえば`index`アクションでは、動作がパラメーターに依存しないため、パラメーターを気にしないことがよくあります。そのような場合には、入力されるパラメーターを使用せず、単に変数名の前にアンダースコアを付けて`_params`とします。これにより、正しいアリティを維持しつつ、コンパイラが未使用の変数について文句を言わないようになります。

## レンダリング

コントローラーには、コンテンツをレンダリングするいくつかの方法があります。もっとも単純なのは、Phoenixが提供する`text/2`関数を使ってプレーンテキストをレンダリングすることです。

試しに、`PageController` の `show` アクションをテキストを返すように書き換えてみましょう。そのためには、次のようにします。

```elixir
def show(conn, %{"messenger" => messenger}) do
  text(conn, "From messenger #{messenger}")
end
```

これで `/hello/Frank` は `From messenger Frank` をHTMLなしのプレーンテキストとして表示するようになりました。

この先のステップは`json/2`関数を使って純粋なJSONをレンダリングすることです。[Jasonライブラリ](https://github.com/michalmuskala/jason)がJSONにデコードできるもの、たとえばmapのようなものを渡す必要があります。（JasonはPhoenixの依存関係の1つです）

```elixir
def show(conn, %{"messenger" => messenger}) do
  json(conn, %{id: messenger})
end
```

ブラウザで `/hello/Frank` に再度アクセスすると、キー `id` が文字列 `"Frank"` にマップされたJSONのブロックが表示されるはずです。

```json
{"id": "Frank"}
```

PhoenixのコントローラーはビューなしでHTMLをレンダリングすることもできます。すでにご存じかもしれませんが、`html/2`関数がそれを実現しています。今回は、このように`show`アクションを実装します。

```elixir
def show(conn, %{"messenger" => messenger}) do
  html(conn, """
   <html>
     <head>
        <title>Passing a Messenger</title>
     </head>
     <body>
       <p>From messenger #{Plug.HTML.html_escape(messenger)}</p>
     </body>
   </html>
  """)
end
```

これで`/hello/Frank`を入力すると、`show`アクションで定義したHTML文字列がレンダリングされます。アクションで書いたものは`eex`テンプレートではないことに注意してください。これは複数行の文字列なので、この`<%= messenger %>`の代わりに `#{Plug.HTML.html_escape(messenger)}`のように`messenger`変数を補間します。

`text/2`、`json/2`、`html/2`関数はPhoenixビューもテンプレートも必要としないことは注目に値します。

`json/2` 関数はAPIを書くのに便利で、他の2つは便利ですが、ほとんどの場合、レスポンスを構築する際はPhoenixのビューを使用します。このために、Phoenixは `render/3` 関数を提供します。

`show` アクションを [リクエストライフサイクルガイド](request_lifecycle.html) で書いたものにロールバックしてみましょう。

```elixir
defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  def show(conn, %{"messenger" => messenger}) do
    render(conn, "show.html", messenger: messenger)
  end
end
```

`render/3`関数が動作するためには、コントローラーとビューは`show.html.eex` テンプレートが存在するテンプレートディレクトリと同じルート名でなければなりません。言い換えれば、`HelloController`は`HelloView`を必要とし、`HelloView`は`lib/hello_web/templates/hello`ディレクトリの存在を必要とし、そのディレクトリには`show.html.eex`テンプレートが含まれていなければなりません。

`render/3` は`messenger` 変数をViewで利用するために、`show` アクションがパラメーターから受け取った値を渡します。

`render`を使用する際にテンプレートに値を渡す必要がある場合は、それは簡単です。`messenger: messenger`で見たようにキーワードリストを渡すこともできますし、`Plug.Conn.assign/3`を使って便利に `conn` を返すこともできます。
```elixir
  def show(conn, %{"messenger" => messenger}) do
    conn
    |> Plug.Conn.assign(:messenger, messenger)
    |> render("show.html")
  end
```

注意: `Phoenix.Controller`をuseすると`Plug.Conn`がimportされるため、`assign/3`の呼び出しを短くしても問題ありません。

複数の値をテンプレートに渡すのは、`assign/3` 関数を繋げても簡単にできます。

```elixir
  def show(conn, %{"messenger" => messenger}) do
    conn
    |> assign(:messenger, messenger)
    |> assign(:receiver, "Dweezil")
    |> render("show.html")
  end
```

一般的に言えば、すべての割り当てが設定されたら、ビューレイヤーを呼び出します。その後、ビューレイヤーはレイアウトと一緒に "show.html" をレンダリングし、レスポンスをブラウザに送り返します。

[ビューとテンプレート](views.html)には独自のガイドがあるので、ここではあまり時間をかけません。これから見ていくのは、コントローラーアクションの内部から、異なるレイアウトを割り当てたり、まったく割り当てなかったりする方法です。

### レイアウトを割り当てる

レイアウトはテンプレートの特別なサブセットにすぎません。これらは`lib/hello_web/templates/layout`にあります。Phoenixはアプリを生成したときに、私たちのために1つ作成してくれました。デフォルトのレイアウトは `app.html.eex` と呼ばれ、デフォルトではすべてのテンプレートがレンダリングされるレイアウトです。

レイアウトは本当にただのテンプレートなので、それらをレンダリングするためのビューが必要です。これは`lib/hello_web/views/layout_view.ex`で定義されている`LayoutView`モジュールです。Phoenixがこのビューを生成してくれたので、レンダリングしたいレイアウトを`lib/hello_web/templates/layout`ディレクトリに置いておけば、新しいビューを作る必要はありません。

しかし、新しいレイアウトを作成する前に、可能な限り単純なことをして、レイアウトのないテンプレートをレンダリングしてみましょう。

`Phoenix.Controller`モジュールには、レイアウトを切り替えるための`put_layout/2`関数が用意されています。これは`conn`を第1引数にとり、レンダリングしたいレイアウトのベース名を文字列で指定します。また、レイアウトを完全に無効にするには `false` を渡します。

`PageController` モジュール `lib/hello_web/controllers/page_controller.ex` の `index` アクションを次のように編集します。

```elixir
def index(conn, _params) do
  conn
  |> put_layout(false)
  |> render("index.html")
end
```

[http://localhost:4000/](http://localhost:4000/)を再読み込みすると、タイトル、ロゴ画像、CSSのスタイルがまったくない、まったく別のページが表示されるはずです。

では、実際に別のレイアウトを作成して、indexテンプレートをレンダリングしてみましょう。例として、アプリケーションの管理セクションのために、ロゴ画像を持たない別のレイアウトがあったとします。これを行うには、既存の`app.html.eex`を同じディレクトリ`lib/hello_web/templates/layout`にある新しいファイル`admin.html.eex`へコピーします。次に、`admin.html.eex`の中のロゴを表示している行を削除してみましょう。

```html
<span class="logo"></span> <!-- remove this line -->
```

次に、`lib/hello_web/controllers/page_controller.ex`の`index`アクションの`put_layout/2`に新しいレイアウトのベースネームを渡します。

```elixir
def index(conn, _params) do
  conn
  |> put_layout("admin.html")
  |> render("index.html")
end
```

ページを読み込んだときに、ロゴのない管理画面レイアウトをレンダリングしているはずです。

### レンダリング形式のオーバーライド

テンプレートを使ってHTMLをレンダリングするのは良いのですが、その場でレンダリング形式を変更する必要がある場合はどうでしょうか？HTMLが必要な時もあれば、プレーンテキストが必要な時もあり、JSONが必要な時もあるとしましょう。その場合はどうすればいいのでしょうか？

Phoenixでは、`_format`クエリ文字列パラメーターを使用して、その場でフォーマットを変更できます。これを実現するために、Phoenixは適切なディレクトリに適切な名前のビューと適切な名前のテンプレートを必要とします。

例として、新しく生成されたアプリの`PageController`のindexアクションを見てみましょう。このアクションには、適切なビュー`PageView`、適切なテンプレートディレクトリ`lib/hello_web/templates/page`、HTMLをレンダリングするための適切なテンプレート`index.html.eex` が含まれています。

```elixir
def index(conn, _params) do
  render(conn, "index.html")
end
```

これにないのは、テキストをレンダリングするための代替テンプレートです。`lib/hello_web/templates/page/index.text.eex`にテンプレートを追加してみましょう。以下に `index.text.eex` テンプレートの例を示します。

```html
OMG, this is actually some text.
```

これを動作させるには、もう少しやるべきことがあります。ルーターに`text`形式を受け入れるように指示する必要があります。これを行うには、`:browser`パイプラインの受け入れ可能なフォーマットのリストに `text`を追加します。`lib/hello_web/router.ex`を開き、`plug:accepts`で`html`と同様に`text`を含めるように変更してみましょう。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
...
```

また、`Phoenix.Controller.get_format/1`が返すテンプレートと同じフォーマットのテンプレートをレンダリングするようにコントローラーに指示する必要があります。テンプレート名"index.html"をアトムバージョン`:index`で代入します。

```elixir
def index(conn, _params) do
  render(conn, :index)
end
```

[`http://localhost:4000/?_format=text`](http://localhost:4000/?_format=text)にアクセスすると、"OMG, this is actually some text."が表示されます。

### レスポンスを直接送信する

上記のレンダリングオプションのどれもニーズに合っていない場合は、Plugが提供する関数を使用して独自のレンダリングオプションを作成できます。たとえば、ステータスが "201" で、ボディが何もないレスポンスを送信したいとします。これは `Plug.Conn.send_resp/3` 関数を使えば簡単にできます。

`PageController` モジュール `lib/hello_web/controllers/page_controller.ex` の `index` アクションを次のように編集してください。

```elixir
def index(conn, _params) do
  conn
  |> send_resp(201, "")
end
```

[http://localhost:4000](http://localhost:4000) をリロードすると、真っ白なページが表示されるはずです。ブラウザの開発者ツールのネットワークタブには「201」という応答ステータスが表示されているはずです。

コンテンツの種類を細かく指定したい場合は、`put_resp_content_type/2` と `send_resp/3` を組み合わせて使うことができます。

```elixir
def index(conn, _params) do
  conn
  |> put_resp_content_type("text/plain")
  |> send_resp(201, "")
end
```

このようにPlug関数を使用することで、必要なレスポンスを作成できます。

### コンテンツタイプを設定する

クエリ文字列パラメーター `_format` と同様に、HTTP Content-Typeヘッダーを修正して適切なテンプレートを提供することで、任意の種類のフォーマットをレンダリングできます。

`index`アクションのxmlバージョンをレンダリングしたい場合、`lib/hello_web/page_controller.ex`に次のようなアクションを実装するでしょう。

```elixir
def index(conn, _params) do
  conn
  |> put_resp_content_type("text/xml")
  |> render("index.xml", content: some_xml_content)
end
```

あとは、有効なxmlを作成した`index.xml.eex`テンプレートを提供する必要があります。

有効なMIMEタイプのリストについては、mimeタイプライブラリの[mime.types](https://github.com/elixir-plug/mime/blob/master/priv/mime.type)のドキュメントを参照してください。

### HTTPステータスを設定する

レスポンスのHTTPステータスコードもコンテンツタイプを設定するのと同じように設定できます。すべてのコントローラーにインポートされている`Plug.Conn`モジュールには、これを行うための`put_status/2`関数があります。

`Plug.Conn.put_status/2`は最初のパラメーターして`conn`を受け取り、2番目のパラメーターは設定したいステータスコードのアトムとして、整数か"フレンドリな名前"を指定します。ステータスコードのアトム表現のリストは`Plug.Conn.Status.code/1`のドキュメントを参照してください。

`PageController`の`index`アクションのステータスを変更してみましょう。

```elixir
def index(conn, _params) do
  conn
  |> put_status(202)
  |> render("index.html")
end
```

提供するステータスコードは有効な数値でなければなりません。

## リダイレクト

リクエストの途中で新しいURLにリダイレクトする必要がよくあります。たとえば、`create`アクションが成功した場合、通常は作成したばかりのリソースへアクセスするため、`show`アクションにリダイレクトします。別の方法として、同じ型のすべてのリソースを表示するために`index`アクションへリダイレクトすることもできます。リダイレクトが有用なケースは他にもたくさんあります。

どのような状況であっても、Phoenixコントローラーには便利な`redirect/2`関数があり、リダイレクトを簡単に行うことができます。Phoenixでは、アプリケーション内のパスへのリダイレクトと、アプリケーション内または外部のURLへのリダイレクトを区別しています。

`redirect/2`を試すために、`lib/hello_web/router.ex`に新しいルートを作成してみましょう。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router
  ...

  scope "/", HelloWeb do
    ...
    get "/", PageController, :index
    get "/redirect_test", PageController, :redirect_test
  end
end
```

次に、`index` アクションを変更して、ただ新しいルートにリダイレクトするだけにします。

```elixir
def index(conn, _params) do
  redirect(conn, to: "/redirect_test")
end
```

最後に、リダイレクト先のアクションを同じファイルに定義してみましょう。これは単にindexをレンダリングしますが、別のアドレスとなります。

```elixir
def redirect_test(conn, _params) do
  render(conn, "index.html")
end
```

[ウェルカムページ](http://localhost:4000)をリロードすると、オリジナルのウェルカムページを表示する`/redirect_test`にリダイレクトされていることがわかります。うまくいきました。

もし気になったら、開発者ツールを開いてネットワークタブをクリックして、`/`ルートに再度アクセスしてみましょう。このページには2つの主要なリクエストがあります - ステータスが`302`の`/`へのアクセスと、ステータスが`200`の`/redirect_test`へのアクセスです。

リダイレクト関数は`conn`とアプリケーション内の相対パスを表す文字列を受け取ることに注目してください。セキュリティ上の理由から、`:to` ヘルパーはアプリケーション内のパスのみをリダイレクトできます。完全修飾されたパスや外部のURLにリダイレクトしたい場合は、代わりに `:external` を使うべきです。

```elixir
def index(conn, _params) do
  redirect(conn, external: "https://elixir-lang.org/")
end
```

また、[ルーティングガイド](routing.html)で学んだパスヘルパーを活用することもできます。

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: Routes.page_path(conn, :redirect_test))
  end
end
```

ルートヘルパーを使用することは、アプリケーション内の任意のページにリンクするための好ましいアプローチです。

## フラッシュメッセージ

アクションの途中でユーザーとコミュニケーションを取る必要がある場合があります。スキーマを更新する際にエラーが発生したかもしれません。アプリケーションに戻ってきたユーザーを歓迎したいのかもしれません。このために、フラッシュメッセージがあります。

`Phoenix.Controller`モジュールは`put_flash/3`と`get_flash/2`関数を提供しており、フラッシュメッセージをキー値のペアとして設定したり取得したりするのに役立ちます。それでは、`HelloWeb.PageController`に2つのフラッシュメッセージを設定してみましょう。

そのためには、`index`アクションを次のように変更します。

```elixir
defmodule HelloWeb.PageController do
  ...
  def index(conn, _params) do
    conn
    |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    |> put_flash(:error, "Let's pretend we have an error.")
    |> render("index.html")
  end
end
```

フラッシュメッセージを表示するためには、それらを取得してテンプレート/レイアウトで表示できるようにする必要があります。最初の部分を行う方法の1つが`get_flash/2`で、これは`conn`と関心があるキーを取得します。そして、そのキーの値を返します。

幸いなことに、私たちのアプリケーションレイアウト`lib/hello_web/templates/layout/app.html.eex`には、フラッシュメッセージを表示するためのマークアップがすでに用意されています。

```html
<p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
<p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
```

[ウェルカムページ](http://localhost:4000/)をリロードすると、"Welcome to Phoenix!"のすぐ上にメッセージが表示されるはずです。

フラッシュ機能は、リダイレクトと組み合わせると便利です。おそらく、追加情報のあるページにリダイレクトしたいと思います。先ほどのリダイレクトアクションを再利用すれば、次のように実現できます。

```elixir
  def index(conn, _params) do
    conn
    |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    |> put_flash(:error, "Let's pretend we have an error.")
    |> redirect(to: Routes.page_path(conn, :redirect_test))
  end
```

これでウェルカムページをリロードするとリダイレクトされ、フラッシュメッセージがもう一度表示されるようになりました。

`Phoenix.Controller`モジュールには、`put_flash/3`と`get_flash/2`の他にも知っておくと便利な関数があります。`clear_flash/1` は`conn`のみを受け取り、セッションに保存されている可能性のあるフラッシュメッセージを削除します。

Phoenixは、どのキーがフラッシュに保存されているかを強制しません。内部的に一貫している限り、すべてうまくいきます。しかし、`:info` と `:error` は一般的なものであり、テンプレートではデフォルトで処理されます。

## アクションフォールバック

アクションフォールバックにより、コントローラーアクションが`%Plug.Conn{}`構造体を返すのに失敗したときに呼び出されるプラグ内のエラー処理コードを一元化できます。これらのプラグは、元々コントローラーアクションに渡された`conn`とアクションの戻り値の両方を受け取ります。

たとえば、`with`を使ってブログ記事を取得し、現在のユーザにそのブログ記事の閲覧を許可する`show`アクションがあるとしましょう。この例では、`fetch_post/1`は記事が見つからなかった場合に`{:error, :not_found}`を返し、`Authorizer.authorize/3`はユーザが権限を持っていない場合に`{:error, :unauthorized}`を返すと期待できます。Phoenixが新しいアプリケーションごとに生成する`ErrorView`を使用して、これらのエラーパスを適切に処理できます。

```elixir
defmodule HelloWeb.MyController do
  use Phoenix.Controller

  def show(conn, %{"id" => id}, current_user) do
    with {:ok, post} <- fetch_post(id),
         :ok <- authorize_user(current_user, :view, post) do
      render(conn, "show.json", post: post)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(HelloWeb.ErrorView)
        |> render(:"404")

      {:error, :unauthorized} ->
        conn
        |> put_status(403)
        |> put_view(HelloWeb.ErrorView)
        |> render(:"403")
    end
  end
end
```

次に、APIで処理されるすべてのコントローラーやアクションに対して、同様のロジックを実装する必要があると想像してみてください。これは多くの繰り返しになります。

その代わりに、これらのエラーケースの処理方法を知っているモジュールプラグを定義できます。コントローラーモジュールプラグなので、プラグをコントローラーとして定義してみましょう。

```elixir
defmodule HelloWeb.MyFallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(HelloWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(403)
    |> put_view(HelloWeb.ErrorView)
    |> render(:"403")
  end
end
```

そして、新しいコントローラーを `action_fallback` として参照し、単に `with` から `else` ブロックを削除するだけです。

```elixir
defmodule HelloWeb.MyController do
  use Phoenix.Controller

  action_fallback HelloWeb.MyFallbackController

  def show(conn, %{"id" => id}, current_user) do
    with {:ok, post} <- fetch_post(id),
         :ok <- authorize_user(current_user, :view, post) do
      render(conn, "show.json", post: post)
    end
  end
end
```

`with` の条件が一致しない場合、 `HelloWeb.MyFallbackController` は元の `conn` とアクションの結果を受け取り、適切に応答します。
