---
layout: 1.4/layout
version: 1.4
group: guides
title: テンプレート
nav_order: 8
hash: 71fafc9392ac49f029a93f403a58253b3a5efc59
---

# テンプレート

テンプレートとは、完全なHTTPレスポンスを形成するためにデータを渡すファイルのことです。 ウェブアプリケーションの場合、これらのレスポンスは通常完全なHTMLドキュメントになります。APIの場合は、ほとんどの場合JSONや場合によってはXMLになります。テンプレートファイルのコードの大部分はマークアップであることが多いですが、Phoenixがコンパイルして評価するためのElixirコードのセクションもあります。Phoenixのテンプレートはあらかじめコンパイルされているため、非常に高速です。 

EExはPhoenixのデフォルトのテンプレートシステムで、RubyのERBによく似ています。実際にはElixir自体の一部であり、PhoenixはEExテンプレートを使用して、新しいアプリケーションを生成しながらルーターやメインアプリケーションビューのようなファイルを作成します。 

[ビューガイド](views.html)で学んだように、デフォルトでは、テンプレートは`lib/hello_web/templates`ディレクトリにあり、ビューにちなんだ名前で整理されています。各ディレクトリには、テンプレートをレンダリングするための独自のビューモジュールがあります。 

### Example

テンプレートの使用方法については、とくに[ページの追加ガイド](adding_pages.html) と [ビューのガイド](views.html) ですでにいくつか見てきました。ここでは同じ領域のいくつかをカバーするかもしれませんが、新しい情報を追加することは間違いありません。

##### hello_web.ex

Phoenixは `lib/hello_web.ex` ファイルを生成し、共通のインポートやエイリアスをグループ化する場所として機能します。ここでの `view` ブロック内のすべての宣言は、すべてのテンプレートに適用されます。

それでは、アプリケーションにいくつか追加を加えて、少し実験してみましょう。

まず、`lib/hello_web/router.ex` で新しいルートを定義してみましょう。


```elixir
defmodule HelloWeb.Router do
  ...

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/test", PageController, :test
  end

  # Other scopes may use custom stacks.
  # scope "/api", Hello do
  #   pipe_through :api
  # end
end
```

続いて、ルートで指定したコントローラーのアクションを定義してみましょう。`lib/hello_web/controllers/page_controller.ex` ファイルに `test/2` アクションを追加します。

```elixir
defmodule HelloWeb.PageController do
  ...

  def test(conn, _params) do
    render(conn, "test.html")
  end
end
```

次に、どのコントローラーとアクションがリクエストを処理しているのかを教えてくれる関数を作成します。

そのためには、`lib/hello_web.ex` の `Phoenix.Controller` から `action_name/1` と `controller_module/1` 関数をインポートする必要があります。


```elixir
  def view do
    quote do
      use Phoenix.View, root: "lib/hello_web/templates",
                        namespace: HelloWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1,
                                        action_name: 1, controller_module: 1]

      ...
    end
  end
```

次に、`lib/hello_web/views/page_view.ex` の下部に `handler_info/1` 関数を定義して、インポートした `controller_module/1` と `action_name/1` 関数を利用します。また、`connection_keys/1` 関数も定義しています。これはすぐに使います。

```elixir
defmodule HelloWeb.PageView do
  use HelloWeb, :view

  def handler_info(conn) do
    "Request Handled By: #{controller_module(conn)}.#{action_name(conn)}"
  end

  def connection_keys(conn) do
    conn
    |> Map.from_struct()
    |> Map.keys()
  end
end
```

ルートを作成しました。新しいコントローラーアクションも作成しました。メインのアプリケーションビューに変更を加えました。あとは `handler_info/1` から取得した文字列を表示するための新しいテンプレートを作成するだけです。`lib/hello_web/templates/page/test.html.eex`を作成してみましょう。

```html
<div class="phx-hero">
  <p><%= handler_info(@conn) %></p>
</div>
```

テンプレート内では `@conn` が `assigns` マップを介して自由に利用できることに注目してください。

[localhost:4000/test](http://localhost:4000/test)にアクセスすると、`Elixir.HelloWeb.PageController.test` によってページが作成されていることがわかります。

`lib/hello_web/views` の中のそれぞれのビューに関数を定義することができます。個々のビューで定義された関数は、そのビューがレンダリングするテンプレートでのみ利用可能です。たとえば、上記の `handler_info` のような関数は、`lib/hello_web/templates/page` にあるテンプレートでのみ利用可能です。

##### リストの表示

これまでのところ、テンプレートでは単数の値しか表示していませんでした - ここでは文字列、他のガイドでは整数です。では、リストのすべての要素を表示するにはどうすればいいのでしょうか？

答えは、Elixirのリスト内包表記を使うことです。

`conn` 構造体のキーのリストを返す関数がテンプレートから利用できるので、あとは `lib/hello_web/templates/page/test.html.eex` テンプレートを少し修正して、それらを表示するだけです。

このようにヘッダとリスト内包を追加することができます。

```html
<div class="phx-hero">
  <p><%= handler_info(@conn) %></p>

  <h3>Keys for the conn Struct</h3>

  <%= for key <- connection_keys(@conn) do %>
    <p><%= key %></p>
  <% end %>
</div>
```

`connection_keys` 関数が返すキーのリストを、繰り返し処理を行うソースリストとして利用します。`<%=` の両方（リスト内包表記の1行目とkeyを表示するための行）に `=` が必要なので注意してください。これがなければ、実際には何も表示されません。

再度 [localhost:4000/test](http://localhost:4000/test) にアクセスすると、すべてのキーが表示されています。


##### テンプレート内でのレンダリング

上のリスト内包の例では、実際に値を表示する部分は非常にシンプルです。

```html
<p><%= key %></p>
```

おそらく、このままにしておいても問題ないでしょう。しかし、多くの場合、この表示コードはやや複雑で、リスト内包の途中でこれを配置すると、テンプレートが読みにくくなります。

簡単な解決策は、別のテンプレートを使うことです！テンプレートは単なる関数呼び出しなので、通常のコードと同じように、より大きなテンプレートを小さな目的の関数で構成することで、より明確な設計を実現することができます。これは、すでに見てきたレンダリングチェーンの続きに過ぎません。レイアウトは、通常のテンプレートがレンダリングされるテンプレートです。通常のテンプレートには、他のテンプレートがレンダリングされている場合があります。

この表示スニペットを独自のテンプレートにしてみましょう。新しいテンプレートファイルを `lib/hello_web/templates/page/key.html.eex` に作成してみましょう。

```html
<p><%= @key %></p>
```

ここでは `key` を リスト内包の一部ではなく `@key` に変更する必要があります。テンプレートへデータは `assigns` マップを用いて渡し、`assigns` マップから `@` でキーを参照して取り出します。実際には `@` は `@key` を `Map.get(assigns, :key)` に変換するマクロです。

テンプレートができたので、`test.html.eex` テンプレート内のリスト内包の中でそれをレンダリングします。

```html
<div class="phx-hero">
  <p><%= handler_info(@conn) %></p>

  <h3>Keys for the conn Struct</h3>

  <%= for key <- connection_keys(@conn) do %>
    <%= render("key.html", key: key) %>
  <% end %>
</div>
```

もう一度、[localhost:4000/test](http://localhost:4000/test)を見てみましょう。ページは以前とまったく同じように見えるはずです。

##### ビュー間の共有テンプレート

多くの場合、小さなデータの断片は、アプリケーションの異なる部分で同じようにレンダリングする必要があります。これらのテンプレートを独自の共有ディレクトリに移動して、アプリ内のどこでも利用可能であることを示すのはグッドプラクティスです。

テンプレートを共有ビューに移動してみましょう。

現在、`key.html.eex`は`HelloWeb.PageView`モジュールによってレンダリングされていますが、現在のスキーマをレンダリングすることを前提としてrender関数をcallしています。これを明示的にして、次のように書き直すことができます。

```html
<div class="phx-hero">
  ...

  <%= for key <- connection_keys(@conn) do %>
    <%= render(HelloWeb.PageView, "key.html", key: key) %>
  <% end %>
</div>
```

これを新しい `lib/hello_web/templates/shared` ディレクトリに配置したいので、そのディレクトリ内のテンプレートをレンダリングするための新しい個別のビュー `lib/hello_web/views/shared_view.ex` が必要です。

```elixir
defmodule HelloWeb.SharedView do
  use HelloWeb, :view
end
```

```html
<%= for key <- connection_keys(@conn) do %>
  <%= render(HelloWeb.SharedView, "key.html", key: key) %>
<% end %>
```

再び [localhost:4000/test](http://localhost:4000/test) に戻ります。ページは以前とまったく同じように見えるはずです。
