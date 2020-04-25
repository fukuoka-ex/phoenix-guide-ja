---
layout: 1.4/layout
version: 1.4
group: guides
title: コントローラー
nav_order: 6
hash: eb3eb71b49de36f778141bdf6b6081a3fcac4d72
---

# コントローラー

Phoenixコントローラーは、中間モジュールとして機能します。アクションと呼ばれる機能は、HTTPリクエストに応答してルーターから呼び出されます。アクションは、必要なデータをすべて収集し、ビューレイヤーを呼び出してテンプレートをレンダリングしたり、JSONレスポンスを返したりする前に、必要なすべてのステップを実行します。

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

たとえば、`lib/hello_web/router.ex`では、新しいアプリでPhoenixが与えてくれるデフォルトのルートのアクション名をindexから変更することができます。

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

アクションには好きな名前をつけることができますが、可能な限り従うべきアクション名の規約があります。Routing Guide](routing.html)で説明しましたが、ここでも簡単に見てみましょう。

- index - 与えられたリソースタイプの全アイテムのリストを表示します
- show - IDを元に個々のアイテムを表示します
- new - 新しいアイテムを作成するためのフォームをレンダリングします
- create - 新しいアイテムのパラメータを受け取り、それをデータストアに保存します
- edit - 個々のアイテムをIDで取得し、編集用のフォームに表示します
- update - 編集されたアイテムのパラメータを受け取り、データストアに保存します
- delete - 削除するアイテムのIDを受け取り、データストアから削除します

これらのアクションにはそれぞれ2つのパラメータが必要で、これはPhoenixが裏で提供するものです。

最初のパラメータは常に`conn`で、ホスト、パス要素、ポート、クエリ文字列などのリクエストに関する情報を保持する構造体です。`conn`は、Elixirのプラグミドルウェアフレームワークを介してPhoenixに提供されます。`conn`の詳細については [プラグのドキュメント](https://hexdocs.pm/plug/Plug.Conn.html)を参照してください。


2番目のパラメータは`params`です。驚くことではありませんが、これはHTTPリクエストで渡されたすべてのパラメータを保持するマップです。レンダリングに渡すことができるシンプルなパッケージのデータを提供するために、関数のシグネチャでparamsとパターンマッチするのは良い習慣です。これは、`lib/hello_web/controllers/hello_controller.ex`の`show`ルートにmessengerパラメータを追加したときに、[ページの追加ガイド](adding_pages.html) で見ました。

```elixir
defmodule HelloWeb.HelloController do
  ...

  def show(conn, %{"messenger" => messenger}) do
    render(conn, "show.html", messenger: messenger)
  end
end
```

いくつかのケース、たとえば`index`アクションでは、動作がパラメータに依存しないため、パラメータを気にしないことがよくあります。そのような場合には、入力されるパラメータを使用せず、単に変数名の前にアンダースコアを付けて`_params`とします。これにより、正しいアリティを維持しつつ、コンパイラが未使用の変数について文句を言わないようになります。

### データの収集

Phoenixには独自のデータアクセスレイヤーはありませんが、Elixirプロジェクトの[Ecto](https://hexdocs.pm/ecto)は、[Postgres](http://www.postgresql.org/)リレーショナルデータベースを使用している人のための非常に優れたソリューションを提供します。PhoenixプロジェクトでのEctoの使用方法については、[Ectoガイド](ecto.html)で説明しています。Ectoでサポートされているデータベースについては、[Ecto READMEのUsageセクション](https://github.com/elixir-lang/ecto#usage)を参照してください。

もちろん、他にも多くのデータアクセスオプションがあります。[Ets](http://www.erlang.org/doc/man/ets.html)と[Dets](http://www.erlang.org/doc/man/dets.html)は、[OTP](http://www.erlang.org/doc/)に組み込まれたキーバリューデータストアです。OTPはまた、[mnesia](http://www.erlang.org/doc/man/mnesia.html)と呼ばれるリレーショナルデータベースも提供しています。ElixirとErlangの両方には、幅広い一般的なデータストアを扱うための多くのライブラリもあります。

データの世界はあなたの思いのままですが、このガイドではこれらのオプションは取り上げません。

## フラッシュメッセージ

アクションの途中でユーザーとコミュニケーションを取る必要がある場合があります。スキーマを更新する際にエラーが発生したかもしれません。アプリケーションに戻ってきたユーザーを歓迎したいのかもしれません。このために、フラッシュメッセージがあります。

`Phoenix.Controller`モジュールは`put_flash/3`と`get_flash/2`関数を提供しており、フラッシュメッセージをキー値のペアとして設定したり取得したりするのに役立ちます。それでは、`HelloWeb.PageController`に2つのフラッシュメッセージを設定してみましょう。

そのためには、`index`アクションを以下のように変更します。

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

`Phoenix.Controller`モジュールは、使用するキーにこだわりはありません。内部的に一貫していれば問題はありません。しかし、`:info`と`:error`は一般的です。

フラッシュメッセージを表示するためには、それらを取得してテンプレート/レイアウトで表示できるようにする必要があります。最初の部分を行う方法の1つが`get_flash/2`で、これは`conn`と関心があるキーを取得します。そして、そのキーの値を返します。

幸いなことに、私たちのアプリケーションレイアウト`lib/hello_web/templates/layout/app.html.eex`には、フラッシュメッセージを表示するためのマークアップがすでに用意されています。

```html
<p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
<p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
```

[Welcome Page](http://localhost:4000/)をリロードすると、"Welcome to Phoenix!"のすぐ上にメッセージが表示されるはずです。

`Phoenix.Controller`モジュールには、`put_flash/3`と`get_flash/2`の他にも知っておくと便利な関数があります。`clear_flash/1` は`conn`のみを受け取り、セッションに保存されている可能性のあるフラッシュメッセージを削除します。

## レンダリング

コントローラーには、コンテンツをレンダリングするいくつかの方法があります。もっとも単純なのは、Phoenixが提供する`text/2`関数を使ってプレーンテキストをレンダリングすることです。

たとえば、パラメータマップからidを受け取る`show`アクションがあり、そのidを持つテキストを返すだけでよいとします。そのためには、次のようにします。

```elixir
def show(conn, %{"id" => id}) do
  text(conn, "Showing id #{id}")
end
```

この`show`アクションに`get "/our_path/:id"`のルートがマップされていると仮定すると、ブラウザで `/our_path/15`にアクセスすると、`Showing id 15`がHTMLなしのプレーンテキストとして表示されるはずです。

この先のステップは`json/2`関数を使って純粋なJSONをレンダリングすることです。[Jasonライブラリ](https://github.com/michalmuskala/jason)がJSONにデコードできるもの、たとえばmapのようなものを渡す必要があります。（JasonはPhoenixの依存関係の一つです）

```elixir
def show(conn, %{"id" => id}) do
  json(conn, %{id: id})
end
```
ブラウザで`our_path/15`に再度アクセスすると、キー`id`が`15`にマップされたJSONのブロックが表示されるはずです。

```json
{"id": "15"}
```

PhoenixのコントローラーはテンプレートなしでHTMLをレンダリングすることもできます。すでにご存じかもしれませんが、`html/2`関数がそれを実現しています。今回は、このように`show`アクションを実装します。

```elixir
def show(conn, %{"id" => id}) do
  html(conn, """
     <html>
       <head>
          <title>Passing an Id</title>
       </head>
       <body>
         <p>You sent in id #{id}</p>
       </body>
     </html>
    """)
end
```

これで`/our_path/15`を押すと、`show`アクションで定義したHTML文字列がレンダリングされ、値 `15` が補間されます。アクションで書いたものは`eex`テンプレートではないことに注意してください。これは複数行の文字列なので、この`<%= id %>`の代わりに `#{id}`のように`id`変数を補間します。

`text/2`、`json/2`、`html/2`関数はPhoenixビューもテンプレートも必要としないことは注目に値します。

`json/2`関数は明らかにAPIを書くのに便利で、他の2つは手軽ですが、テンプレートを値を渡してレイアウトにレンダリングするのは非常に一般的なケースです。

このため、Phoenixは`render/3`関数を提供しています。

興味深いことに、`render/3`は`Phoenix.Controller`の代わりに`Phoenix.View`モジュールで定義されていますが、便宜上、`Phoenix.Controller`にエイリアスを付けています。

[ページの追加ガイド](adding_pages.html)でrender関数をすでに見ています。`lib/hello_web/controllers/hello_controller.ex`の`show`アクションは以下のようになっています。

```elixir
defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  def show(conn, %{"messenger" => messenger}) do
    render(conn, "show.html", messenger: messenger)
  end
end
```

`render/3`関数が正しく動作するためには、コントローラーが個々のビューと同じルート名を持っていなければなりません。また、個々のビューは、`show.html.eex`テンプレートが存在するテンプレートディレクトリと同じルート名でなければなりません。言い換えれば、`HelloController`は`HelloView`を必要とし、`HelloView`は`lib/hello_web/templates/hello`ディレクトリの存在を必要とし、そのディレクトリには`show.html.eex`テンプレートが含まれていなければなりません。

また、`render/3`は`show`アクションが`messenger`のためにparamsハッシュから受け取った値をテンプレートに渡して補間します。

`render`を使う際にテンプレートへ値を渡す必要がある場合、それは簡単です。`messenger: messenger`で見たように辞書を渡すこともできますし、`Plug.Conn.assign/3`を使えば便利に`conn`を返すことができます。

```elixir
def index(conn, _params) do
  conn
  |> assign(:message, "Welcome Back!")
  |> render("index.html")
end
```

注意: `Phoenix.Controller`モジュールは`Plug.Conn`をインポートしているので、`assign/3`の呼び出しを短くしても問題ありません。

このメッセージは`index.html.eex`テンプレートやレイアウトの中で`<%= @message %>`でアクセスできます。

テンプレートに複数の値を渡すのは簡単で、`assign/3`の関数をパイプラインで接続します。

```elixir
def index(conn, _params) do
  conn
  |> assign(:message, "Welcome Back!")
  |> assign(:name, "Dweezil")
  |> render("index.html")
end
```

これにより、`index.html.eex`テンプレートで`@message`と`@name`の両方が利用可能になります。

いくつかのアクションで上書きできるようなデフォルトのウェルカムメッセージを用意したい場合はどうすればよいでしょうか? これは簡単で、コントローラーアクションに向かう途中で`plug`を使って`conn`を変換するだけです。

```elixir
plug :assign_welcome_message, "Welcome Back"

def index(conn, _params) do
  conn
  |> assign(:message, "Welcome Forward")
  |> render("index.html")
end

defp assign_welcome_message(conn, msg) do
  assign(conn, :message, msg)
end
```

もし、`assign_welcome_message`をプラグに加えたいが、一部のアクションにだけ適用したい場合はどうすればよいでしょうか？Phoenixは、プラグを適用するアクションを指定することでこの問題を解決します。もし`plug :assign_welcome_message`を`index`と`show`のアクションだけに適用したい場合は、このようにします。

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  plug :assign_welcome_message, "Hi!" when action in [:index, :show]
...
```

### レスポンスを直接送信する

上記のレンダリングオプションのどれもニーズに合っていない場合は、プラグが提供する関数を使用して独自のレンダリングオプションを作成することができます。たとえば、ステータスが"201"で、ボディが何もないレスポンスを送信したいとします。これは`send_resp/3`関数を使えば簡単にできます。

```elixir
def index(conn, _params) do
  conn
  |> send_resp(201, "")
end
```

[http://localhost:4000](http://localhost:4000)を再読み込みすると、真っ白なページが表示されるはずです。ブラウザの開発者ツールのネットワークタブには"201"という応答ステータスが表示されているはずです。

コンテンツの種類を細かく指定したい場合は、`put_resp_content_type/2`と`send_resp/3`を組み合わせて使うことができます。

```elixir
def index(conn, _params) do
  conn
  |> put_resp_content_type("text/plain")
  |> send_resp(201, "")
end
```

このようにPlug関数を使用することで、必要なレスポンスだけを作成することができます。

しかし、レンダリングはテンプレートだけでは終わりません。デフォルトでは、テンプレートのレンダリング結果はレイアウトに挿入され、それもレンダリングされます。

[テンプレートとレイアウト](templates.html)には独自のガイドがあるので、ここではあまり時間をかけません。これから見ていくのは、コントローラーアクションの内部から、異なるレイアウトを割り当てたり、まったく割り当てなかったりする方法です。

### レイアウトを割り当てる

レイアウトはテンプレートの特別なサブセットにすぎません。これらは`lib/hello_web/templates/layout`にあります。Phoenixはアプリを生成したときに、私たちのために1つを作成してくれました。これは`app.html.eex`と呼ばれ、デフォルトですべてのテンプレートがレンダリングされるレイアウトです。

レイアウトは本当にただのテンプレートなので、それらをレンダリングするためのビューが必要です。これは`lib/hello_web/views/layout_view.ex`で定義されている`LayoutView`モジュールです。Phoenixがこのビューを生成してくれたので、レンダリングしたいレイアウトを`lib/hello_web/templates/layout`ディレクトリに置いておけば、新しいビューを作る必要はありません。

しかし、新しいレイアウトを作成する前に、可能な限り単純なことをして、レイアウトのないテンプレートをレンダリングしてみましょう。

`Phoenix.Controller`モジュールには、レイアウトを切り替えるための`put_layout/2`関数が用意されています。これは`conn`を第1引数にとり、レンダリングしたいレイアウトのベース名を文字列で指定します。この関数の別の句が第2引数のブール値`false`にマッチし、これがPhoenixのウェルカムページをレイアウトなしでレンダリングする方法です。

生成したばかりのPhoenixアプリで、`lib/hello_web/controllers/page_controller.ex`にある`PageController`モジュールの`index`アクションを以下のように編集します。

```elixir
def index(conn, _params) do
  conn
  |> put_layout(false)
  |> render("index.html")
end
```
[http://localhost:4000/](http://localhost:4000/)を再読み込みすると、タイトル、ロゴ画像、CSSのスタイルがまったくない、まったく別のページが表示されるはずです。

非常に重要です! パイプライン内の関数呼び出しでは、パイプ演算子が非常に強固に結合するため、引数の周りに括弧を使用することが非常に重要です。これは解析の問題や非常に奇妙な結果につながります。

もしこのようなスタックトレースが出てきたら

```console
**(FunctionClauseError) no function clause matching in Plug.Conn.get_resp_header/2

Stacktrace

    (plug) lib/plug/conn.ex:353: Plug.Conn.get_resp_header(false, "content-type")
```

引数が第1引数として`conn`を置き換えてしまう場合、最初にチェックすべきことの1つは、正しい場所に括弧があるかどうかです。

これは問題ありません。

```elixir
def index(conn, _params) do
  conn
  |> put_layout(false)
  |> render("index.html")
end
```

一方、これはうまく動作しません。

```elixir
def index(conn, _params) do
  conn
  |> put_layout false
  |> render "index.html"
end
```

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

Phoenixでは、`_format`クエリ文字列パラメータを使用して、その場でフォーマットを変更できます。これを実現するために、Phoenixは適切なディレクトリに適切な名前のビューと適切な名前のテンプレートを必要とします。

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

[http://localhost:4000/?_format=text](http://localhost:4000/?_format=text)に行くと、`OMG, this is actually some text.`が表示されます。

もちろん、テンプレートにデータを渡すこともできます。関数定義の`params`の前にある`_`を削除して、メッセージパラメータを受け取るようにアクションを変更してみましょう。今回は、テキストテンプレートのやや柔軟性の低い文字列バージョンを使用します。

```elixir
def index(conn, params) do
  render(conn, "index.text", message: params["message"])
end
```

そして、テキストテンプレートに少しだけ追加してみましょう。

```html
OMG, this is actually some text. <%= @message %>
```

これで`http://localhost:4000/?_format=text&message=CrazyTown`に行くと、"OMG, this is actually some text. CrazyTown"と表示されます。

### コンテンツタイプを設定する

クエリ文字列パラメータ`_format`と同様に、HTTP Content-Typeヘッダを修正して適切なテンプレートを提供することで、任意の種類のフォーマットをレンダリングすることができます。

`index`アクションのxmlバージョンをレンダリングしたい場合、`lib/hello_web/page_controller.ex`に次のようなアクションを実装するでしょう。

```elixir
def index(conn, _params) do
  conn
  |> put_resp_content_type("text/xml")
  |> render("index.xml", content: some_xml_content)
end
```

あとは、有効なxmlを作成した`index.xml.eex`テンプレートを提供する必要があります。

有効なMIMEタイプのリストについては、mimeタイプライブラリの[mime.types](https://github.com/elixir-lang/mime/blob/master/lib/mime.types)のドキュメントを参照してください。

### HTTPステータスを設定する

レスポンスのHTTPステータスコードもコンテンツタイプを設定するのと同じように設定できます。すべてのコントローラーにインポートされている`Plug.Conn`モジュールには、これを行うための`put_status/2`関数があります。

`Plug.Conn.put_status/2`は最初のパラメータとして`conn`を受け取り、2番目のパラメータには設定したいステータスコードのアトムとして、整数か"フレンドリな名前"を指定します。ステータスコードのアトム表現のリストは`Plug.Conn.Status.code/1`のドキュメントを参照してください。

`PageController`の`index`アクションのステータスを変更してみましょう。

```elixir
def index(conn, _params) do
  conn
  |> put_status(202)
  |> render("index.html")
end
```

提供するステータスコードは有効でなければなりません。Phoenixが動作するWebサーバである[Cowboy](https://github.com/ninenines/cowboy)は、無効なコードに対してエラーをスローします。開発ログ（IEXセッション）を見たり、ブラウザのウェブ検査ネットワークツールを使用したりすると、ページをリロードするときにステータスコードが設定されているのがわかります。

アクションがレンダリングまたはリダイレクトでレスポンスを送信する場合、コードを変更してもレスポンスの動作は変わりません。たとえば、ステータスを404または500に設定してから`render("index.html")`を実行しても、エラーページは表示されません。同様に、300レベルのコードが実際にリダイレクトすることはありません。(コードが挙動に影響を与えたとしても、どこにリダイレクトすればいいのかはわかりません)。

たとえば、`HelloWeb.PageController`の`index`アクションの以下の実装は、デフォルトの`not_found`の振る舞い通り、レンダリングを*行いません*。

```elixir
def index(conn, _params) do
  conn
  |> put_status(:not_found)
  |> render("index.html")
end
```

`HelloWeb.PageController`から404ページをレンダリングする正しい方法は、次のようになります。

```elixir
def index(conn, _params) do
  conn
  |> put_status(:not_found)
  |> put_view(HelloWeb.ErrorView)
  |> render("404.html")
end
```

## リダイレクト

リクエストの途中で新しいURLにリダイレクトする必要があることがよくあります。たとえば、`create`アクションが成功した場合、通常は作成したばかりのスキーマへアクセスするため、`show`アクションにリダイレクトします。別の方法として、同じ型のすべてのスキーマを表示するために`index`アクションにリダイレクトすることもできます。リダイレクトが有用なケースは他にもたくさんあります。

どのような状況であっても、Phoenixコントローラーには便利な`redirect/2`関数があり、リダイレクトを簡単に行うことができます。Phoenixでは、アプリケーション内のパスへのリダイレクトと、アプリケーション内または外部のURLへのリダイレクトを区別しています。

`redirect/2`を試すために、`lib/hello_web/router.ex`に新しいルートを作成してみましょう。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router
  ...

  scope "/", HelloWeb do
    ...
    get "/", PageController, :index
  end

  # New route for redirects
  scope "/", HelloWeb do
    get "/redirect_test", PageController, :redirect_test, as: :redirect_test
  end
  ...
end
```

次に、`index` アクションを変更して、ただ新しいルートにリダイレクトするだけにします。

```elixir
def index(conn, _params) do
  redirect(conn, to: "/redirect_test")
end
```

最後に、リダイレクト先のアクションを同じファイルに定義してみましょう。

```elixir
def redirect_test(conn, _params) do
  text(conn, "Redirect!")
end
```

[Welcome Page](http://localhost:4000)をリロードすると、`Redirect!`文字列がレンダリングされた`/redirect_test`にリダイレクトされていることがわかります。うまくいきました。

もし気になったら、開発者ツールを開いてネットワークタブをクリックして、`/`ルートに再度アクセスしてみましょう。このページには2つの主要なリクエストがあります - ステータスが`302`の`/`へのアクセスと、ステータスが`200`の`/redirect_test`へのアクセスです。

リダイレクト関数は`conn`とアプリケーション内の相対パスを表す文字列を受け取ることに注目してください。また、`conn`と完全修飾されたURLを表す文字列を受け取ることもできます。

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
    redirect(conn, to: Routes.redirect_test_path(conn, :redirect_test))
  end
end
```

アトム `:to`を使った`redirect/2`はパスを期待しているので、ここではurlヘルパーを使うことができないことに注意してください。たとえば、以下のようにすると失敗します。

```elixir
def index(conn, _params) do
  redirect(conn, to: Routes.redirect_test_url(conn, :redirect_test))
end
```

urlヘルパーを使って完全なurlを`redirect/2`に渡したい場合は、`:external`というアトムを使わなければなりません。この例のように、`:external`を使うためにはURLはアプリケーションの外部である必要はないことに注意してください。

```elixir
def index(conn, _params) do
  redirect(conn, external: Routes.redirect_test_url(conn, :redirect_test))
end
```

## アクションフォールバック

アクションフォールバックにより、コントローラーアクションが`Plug.Conn.t`を返すのに失敗したときに呼び出されるプラグ内のエラー処理コードを一元化することができます。これらのプラグは、元々コントローラーアクションに渡されたconnとアクションの戻り値の両方を受け取ります。

たとえば、`with`を使ってブログ記事を取得し、現在のユーザにそのブログ記事の閲覧を許可する`show`アクションがあるとしましょう。この例では、`Blog.fetch_post/1`は記事が見つからなかった場合に`{:error, :not_found}`を返し、`Authorizer.authorize/3`はユーザが権限を持っていない場合に`{:error, :unauthorized}`を返すと予想できます。これらの非ハッピーパスのエラービューを直接レンダリングすることができます。

```elixir
defmodule HelloWeb.MyController do
  use Phoenix.Controller
  alias Hello.{Authorizer, Blog}
  alias HelloWeb.ErrorView

  def show(conn, %{"id" => id}, current_user) do
    with {:ok, post} <- Blog.fetch_post(id),
         :ok <- Authorizer.authorize(current_user, :view, post) do

      render(conn, "show.json", post: post)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(ErrorView)
        |> render(:"404")
      {:error, :unauthorized} ->
        conn
        |> put_status(403)
        |> put_view(ErrorView)
        |> render(:"403")
    end
  end
end
```

多くの場合 - とくに API 用のコントローラーを実装する場合 - このようなコントローラーでのエラー処理は多くの繰り返しになります。その代わりに、これらのエラーケースを処理する方法を知っているプラグを定義することができます。

```elixir
defmodule HelloWeb.MyFallbackController do
  use Phoenix.Controller
  alias HelloWeb.ErrorView

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(403)
    |> put_view(ErrorView)
    |> render(:"403")
  end
end
```

そして、action_fallbackを使ってそのプラグを参照し、単に`with`から`else`ブロックを削除します。プラグは元のconnだけでなくアクションの結果も受け取り、適切に応答します。

```elixir
defmodule HelloWeb.MyController do
  use Phoenix.Controller
  alias Hello.{Authorizer, Blog}

  action_fallback HelloWeb.MyFallbackController

  def show(conn, %{"id" => id}, current_user) do
    with {:ok, post} <- Blog.fetch_post(id),
         :ok <- Authorizer.authorize(current_user, :view, post) do

      render(conn, "show.json", post: post)
    end
  end
end
```

## プラグパイプラインの停止

「コントローラーはプラグです...」と前述したように、コントローラーはプラグパイプラインの最後に呼び出されるプラグです。 パイプラインのどの段階でも、処理を停止する原因があるかもしれません - 通常はリダイレクトやレスポンスのレンダリングが原因です。`Plug.Conn.t`には`:halted`キーがあり、これをtrueに設定すると、下流のプラグはスキップされます。これは`Plug.Conn.halt/1`を使えば簡単にできます。

`HelloWeb.PostFinder`プラグを考えてみましょう。呼び出し時に、指定されたidに関連する投稿が見つかった場合は`conn.assigns`に追加し、投稿が見つからなかった場合は404ページで応答します。

```elixir
defmodule HelloWeb.PostFinder do
  use Plug
  import Plug.Conn

  alias Hello.Blog

  def init(opts), do: opts

  def call(conn, _) do
    case Blog.get_post(conn.params["id"]) do
      {:ok, post} ->
        assign(conn, :post, post)
      {:error, :notfound} ->
        conn
        |> send_resp(404, "Not found")
    end
  end
end
```

プラグパイプラインの一部としてこのプラグを呼び出しても、下流のプラグは処理されます。404レスポンスが発生した場合に下流のプラグが処理されないようにしたい場合は、単に`Plug.Conn.halt/1`を呼び出すだけです。

```elixir
    ...
    case Blog.get_post(conn.params["id"]) do
      {:ok, post} ->
        assign(conn, :post, post)
      {:error, :notfound} ->
        conn
        |> send_resp(404, "Not found")
        |> halt()
    end
```

ここで重要なのは、`halt/1`は単に`Plug.Conn.t`の`:halted`キーを`true`に設定するだけであるということです。これは下流のプラグが起動されないようにするのには十分ですが、ローカルでのコードの実行を止めることはできません。次のような記述は、

```elixir
conn
|> send_resp(404, "Not found")
|> halt()
```

... 次の記述と機能的に等価です。...

```elixir
conn
|> halt()
|> send_resp(404, "Not found")
```

haltingはプラグパイプラインの継続を停止するだけであることにも注意しましょう。関数プラグの実装が `:halted`の値をチェックしない限り、プラグはまだ実行されます。

```elixir
def post_authorization_plug(%{halted: true} = conn, _), do: conn
def post_authorization_plug(conn, _) do
  ...
end
```
