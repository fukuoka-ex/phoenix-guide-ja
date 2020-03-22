---
layout: default
group: guides
title: ルーティング
nav_order: 3
hash: a61eb0644628e25add5f7ba5d69a337a2abd2e5d
---

# ルーティング

ルーターは、Phoenixアプリケーションのメインハブです。ルーターは、HTTPリクエストをコントローラーのアクションにマッチさせ、リアルタイムのチャネルハンドラをつなぎ、ミドルウェアを一連のルートにスコープするための一連のパイプライン変換を定義します。

Phoenixが生成するルーターファイル`lib/hello_web/router.ex`は、次のようになります:

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloWeb do
  #   pipe_through :api
  # end
end
```

ルーターとコントローラーのモジュール名の両方には、`HelloWeb`ではなく、あなたがアプリケーションに与えた名前がプレフィックスとして付けられます。

このモジュールの最初の行である`use HelloWeb, :router`は、Phoenixルーターの関数を特定のルーターで利用できるようにするだけです。

このガイドではスコープのセクションがありますので、ここでは`scope "/", HelloWeb do`のブロックに時間を割くことはありません。`pipe_through :browser`行については、このガイドのパイプラインのセクションで詳しく説明します。今のところ、パイプラインによってミドルウェアの変換を異なるルートに適用できることだけは知っておく必要があります。

ただし、スコープブロック内には、最初の実ルートがあります:

```elixir
get "/", PageController, :index
```

`get`はPhoenixのマクロで、1つの`match/5`関数定義に展開され、これはHTTPメソッドのGETに対応します。同様のマクロは、POST、PUT、PATCH、DELETE、OPTIONS、CONNECT、TRACE、HEADを含む他のHTTPメソッドにも存在します。

これらのマクロの最初の引数はパスです。ここでは、アプリケーションのルートである`/`です。次の2つの引数は、このリクエストを処理させたいコントローラーとアクションです。これらのマクロは他のオプションを取ることもできます。これについては、このガイドの後半で説明します。

これがルーターモジュールの中で唯一のルートであった場合、`match/5`関数はマクロを展開した後に次のようになります。

```elixir
def match(:get, "/", PageController, :index, [])
```

`match/5`関数はコネクションを設定し、マッチしたコントローラーアクションを呼び出します。

ルートを追加していくと、ルーターモジュールにmatch関数定義が追加されていきます。これらは、Elixirの他のmulti-clause function（訳注：Elixirでは同名の関数を複数定義できます）と同じように動作します。これらは上から順に試行され、与えられたパラメータ(HTTPメソッドとパス)にマッチする最初の節が実行されます。マッチする関数が見つかると、検索は停止し、他の関数は試行されません。

つまり、コントローラーやアクションに関係なく、HTTPメソッドとパスを元にして、絶対にマッチしないルートを作ることができるということです。

曖昧なルートを作成しても、ルーターはコンパイルしますが、警告が表示されます。これを実際に見てみましょう。

ルーターの`scope "/", HelloWeb do`ブロックの一番下にこのルートを定義します。

```elixir
get "/", RootController, :index
```

そして、プロジェクトのルートで`mix compile`を実行します。

## ルートを調べる

Phoenixはアプリケーションのルートを調べるための素晴らしいツールであるMixタスク`phx.routes`を提供しています。

これがどのように動作するか見てみましょう。新しく生成されたPhoenixアプリケーションのルートに移動し、`mix phx.routes`を実行してください。(まだ実行していない場合は、`routes`タスクを実行する前に`mix do deps.get, compile`を実行する必要があります)。現在持っている唯一のルートから生成された以下のようなものが表示されるはずです。

```console
$ mix phx.routes
page_path  GET  /  HelloWeb.PageController :index
```

この出力は、アプリケーションのルートに対するHTTP GETリクエストが`HelloWeb.PageController`の`index`アクションによって処理されることを示しています。

`page_path`はPhoenixがパスヘルパーと呼んでいるものの一例です。


## リソース

ルーターは`get`,`post`,`put`などのHTTPメソッド用のマクロ以外のマクロもサポートしています。その中でもっとも重要なのは`resources`で、これは`match/5`関数の8つの関数定義に展開されます。

このようにリソースを`lib/hello_web/router.ex`ファイルに追加してみましょう。

```elixir
scope "/", HelloWeb do
  pipe_through :browser

  get "/", PageController, :index
  resources "/users", UserController
end
```

実際には`HelloWeb.UserController`を持っていなくても問題ありません。

次に、プロジェクトのルートに行って`mix phx.routes`を実行します。

次のようなものが表示されるはずです:

```elixir
user_path  GET     /users           HelloWeb.UserController :index
user_path  GET     /users/:id/edit  HelloWeb.UserController :edit
user_path  GET     /users/new       HelloWeb.UserController :new
user_path  GET     /users/:id       HelloWeb.UserController :show
user_path  POST    /users           HelloWeb.UserController :create
user_path  PATCH   /users/:id       HelloWeb.UserController :update
           PUT     /users/:id       HelloWeb.UserController :update
user_path  DELETE  /users/:id       HelloWeb.UserController :delete
```

もちろん、`HelloWeb`はプロジェクト名に置き換わります。

これがHTTPメソッド、パス、コントローラーのアクションの標準的な表です。少し順番を変えて個別に見てみましょう。

- `/users`へのGETリクエストは、`index`アクションを呼び出してすべてのユーザーを表示します。
- `/users/:id`へのGETリクエストは、IDを指定して`show`アクションを呼び出し、そのIDで識別されるユーザーーを表示します。
- `/users/new`へのGETリクエストは`new`アクションを呼び出し、新しいユーザーを作成するためのフォームを表示します。
- `/users`へのPOSTリクエストは`create`アクションを呼び出し、新しいユーザーをデータストアに保存します。
- `/users/:id/edit`へのGETリクエストは、IDを指定して`edit`アクションを呼び出し、データストアからユーザーを取得して編集用のフォームに情報を表示します。
- PATCHリクエストを`/users/:id`に送ると、IDを指定して`update`アクションを呼び出し、更新されたユーザーをデータストアに保存します。
- また、`/users/:id`へのPUTリクエストも`update`アクションを呼び出し、IDを指定して更新されたユーザーをデータストアに保存する。
- DELETEリクエストを`/users/:id`に行うと、IDを指定して`delete`アクションを呼び出し、データストアから個々のユーザーを削除します。

これらのルートをすべて必要としない場合は、`:only`と`:except`オプションを使って選択できます。

例えば、読み取り専用の投稿リソースがあるとしましょう。このように定義できます。

```elixir
resources "/posts", PostController, only: [:index, :show]
```

これで、indexとshowアクションへのルートだけが定義されたことになります。

```elixir
post_path  GET     /posts      HelloWeb.PostController :index
post_path  GET     /posts/:id  HelloWeb.PostController :show
```

同様に、コメントリソースを持っていて、そのリソースを削除するためのルートを提供したくない場合は、以下のようなルートを定義できます。

```elixir
resources "/comments", CommentController, except: [:delete]
```

これで`mix phx.routes`を実行すると、削除アクションへのDELETEリクエスト以外のすべてのルートがあることがわかります。

```elixir
comment_path  GET    /comments           HelloWeb.CommentController :index
comment_path  GET    /comments/:id/edit  HelloWeb.CommentController :edit
comment_path  GET    /comments/new       HelloWeb.CommentController :new
comment_path  GET    /comments/:id       HelloWeb.CommentController :show
comment_path  POST   /comments           HelloWeb.CommentController :create
comment_path  PATCH  /comments/:id       HelloWeb.CommentController :update
              PUT    /comments/:id       HelloWeb.CommentController :update
```

リソースルートをカスタマイズするための追加オプションは`Phoenix.Router.resources/4`を参照してください。

## フォワード

`Phoenix.Router.forward/4`マクロは、特定のパスで始まるすべてのリクエストを、特定のプラグへ転送するために使用できます。システムの一部がバックグラウンドでジョブを実行しているとします（別のアプリケーションやライブラリであっても構いません）。この管理インターフェースには、以下のようにして転送できます。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  ...

  scope "/", HelloWeb do
    ...
  end

  forward "/jobs", BackgroundJob.Plug
end
```

これは、`/jobs`で始まるすべてのルートが`HelloWeb.BackgroundJob.Plug`モジュールに送られることを意味します。

パイプラインで`forward/4`マクロを使うこともできます。もしユーザーが認証されていて管理者であることを確認してジョブページを表示させたい場合は、ルーター以下のように記述します。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  ...

  scope "/" do
    pipe_through [:authenticate_user, :ensure_admin]
    forward "/jobs", BackgroundJob.Plug
  end
end
```

これは、`authenticate_user`と`ensure_admin`パイプライン内のプラグが`BackgroundJob.Plug`の前に呼び出され、適切な応答を送信して`halt()`を呼び出すことができることを意味します。

プラグの`init/1`コールバックに渡される`opts`は第3引数として渡すことができます。たとえば、バックグラウンドジョブページでは、ページに表示するアプリケーションの名前を設定することができるとすると、これは次のように記述します：

```elixir
forward "/jobs", BackgroundJob.Plug, name: "Hello Phoenix"
```

4番目の`router_opts`引数があります。これらのオプションの概要は、`Phoenix.Router.scope/2`のドキュメントに記載されています。

任意のモジュールプラグに転送することは可能ですが、別のエンドポイントに転送することはオススメしません。これは、アプリと転送されたエンドポイントによって定義されたプラグが2回呼び出され、エラーが発生する可能性があるためです。

実際のバックグラウンドジョブワーカーを書くことは、このガイドの範囲を超えています。しかし、便宜上、上記のコードをテストできるようにするために、`BackgroundJob.Plug`の実装を以下に示します。

```elixir
defmodule HelloWeb.BackgroundJob.Plug do
  def init(opts), do: opts
  def call(conn, opts) do
    conn
    |> Plug.Conn.assign(:name, Keyword.get(opts, :name, "Background Job"))
    |> HelloWeb.BackgroundJob.Router.call(opts)
  end
end

defmodule HelloWeb.BackgroundJob.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome to #{conn.assigns.name}")
  get "/active", do: send_resp(conn, 200, "5 Active Jobs")
  get "/pending", do: send_resp(conn, 200, "3 Pending Jobs")
  match _, do: send_resp(conn, 404, "Not found")
end
```

## パスヘルパー

パスヘルパーは、個々のアプリケーションのために`Router.Helpers`モジュール上で動的に定義される関数です。私たちの場合は、`HelloWeb.Router.Helpers`です。それらの名前は、ルート定義で使用されるコントローラーの名前に由来しています。私たちのコントローラーは`HelloWeb.PageController`で、`page_path`はアプリケーションのルートへのパスを返す関数です。

説明すると長くなりますね。実際に見てみましょう。プロジェクトのルートで`iex -S mix`を実行します。ルーターヘルパーの`page_path`関数を`Endpoint`かコネクションとアクションを引数として呼び出すと、パスを返してくれます。

```elixir
iex> HelloWeb.Router.Helpers.page_path(HelloWeb.Endpoint, :index)
"/"
```

テンプレート内で`page_path`関数を使用してアプリケーションのルートにリンクすることができるので、これは重要です。テンプレートの中でこのヘルパーを使うことができます。

```html
<a href="<%= Routes.page_path(@conn, :index) %>">To the Welcome Page!</a>
```

完全な`HelloWeb.Router.Helpers.page_path`名の代わりに`Routes.page_path`を使用できる理由は、`HelloWeb.Router.Helpers`はデフォルトで`view/0`定義（`lib/hello_web.ex`）内で`Routes`としてエイリアスされており、`use HelloWeb, :view`を通じてテンプレートで利用できるようになっているからです。もちろん、`HelloWeb.Router.Helpers.page_path(@conn, :index)`を代わりに使用することもできますが、簡潔さのためにエイリアスされたバージョンを使用するのが慣例です（エイリアスは、ビュー、コントローラー、テンプレートで使用するためだけに自動的に設定されることに注意してください。これらの外では、フルネームか、モジュール定義内で`alias HelloWeb.Router.Helpers, as. Routes`のようにエイリアスする必要があります）。詳細は [ビューガイド](views.html) を参照してください。

これは、ルーター内のルートのパスを変更しなければならない場合に、非常に有益です。パスヘルパーはルートから動的に構築されるので、テンプレート内の`page_path`への呼び出しは今まで通り機能します。


### パスヘルパーの詳細

ユーザーリソースのために`phx.routes`タスクを実行すると、出力の各行のパスヘルパー関数として`user_path`がリストアップされました。これはそれぞれのアクションに対して以下のように変換されます。

```elixir
iex> alias HelloWeb.Router.Helpers, as: Routes
iex> alias HelloWeb.Endpoint
iex> Routes.user_path(Endpoint, :index)
"/users"

iex> Routes.user_path(Endpoint, :show, 17)
"/users/17"

iex> Routes.user_path(Endpoint, :new)
"/users/new"

iex> Routes.user_path(Endpoint, :create)
"/users"

iex> Routes.user_path(Endpoint, :edit, 37)
"/users/37/edit"

iex> Routes.user_path(Endpoint, :update, 37)
"/users/37"

iex> Routes.user_path(Endpoint, :delete, 17)
"/users/17"
```

クエリ文字列を持つパスはどうでしょうか？オプションの第4引数にキーと値のペアを追加することで、パスヘルパーはクエリ文字列の中のペアを返します。

```elixir
iex> Routes.user_path(Endpoint, :show, 17, admin: true, active: false)
"/users/17?admin=true&active=false"
```

パスの代わりに完全なURLが必要な場合はどうすればいいのでしょうか？その場合はパスを`_path`を`_url`に置き換えてください。

```elixir
iex(3)> Routes.user_url(Endpoint, :index)
"http://localhost:4000/users"
```

`_url`関数は、環境ごとに設定された設定パラメータから、フルURLを構築するために必要なホスト、ポート、プロキシポート、SSLの情報を取得します。設定については、それ自身のガイドで詳しく説明します。今のところは、自分のプロジェクトの`config/dev.exs`ファイルを見て、これらの値を確認することができます。

可能な限り、`Endpoint`の代わりに`conn`を渡してください。

## ネストされたリソース

Phoenixルーターにリソースを入れ子にすることも可能です。例えば、`posts`リソースを持っていて、`users`と多対一の関係を持っているとします。つまり、1人のユーザーが多くの投稿を作成することができ、個々の投稿は1人のユーザーにしか属していないということです。これを表現するには、`lib/hello_web/router.ex`の中に次のような入れ子になったルートを追加します。

```elixir
resources "/users", UserController do
  resources "/posts", PostController
end
```

`mix phx.routes`を実行すると、上で見た`users`のルートに加えて、以下のようなルートが得られます。

```elixir
...
user_post_path  GET     /users/:user_id/posts           HelloWeb.PostController :index
user_post_path  GET     /users/:user_id/posts/:id/edit  HelloWeb.PostController :edit
user_post_path  GET     /users/:user_id/posts/new       HelloWeb.PostController :new
user_post_path  GET     /users/:user_id/posts/:id       HelloWeb.PostController :show
user_post_path  POST    /users/:user_id/posts           HelloWeb.PostController :create
user_post_path  PATCH   /users/:user_id/posts/:id       HelloWeb.PostController :update
                PUT     /users/:user_id/posts/:id       HelloWeb.PostController :update
user_post_path  DELETE  /users/:user_id/posts/:id       HelloWeb.PostController :delete
```

これらのルートはそれぞれユーザーIDに投稿をスコープしていることがわかります。最初のルートでは、`PostController` `index`アクションを呼び出しますが、`user_id`を渡します。これは、そのユーザーのすべての投稿を表示することを意味します。これらすべてのルートに同じスコープが適用されます。

ネストしたルートに対してパスヘルパー関数を呼び出す際には、ルート定義にあった順にIDを渡す必要があります。次の`show`ルートでは、`42`が`user_id`で、`17`が`post_id`です。始める前に、`HelloWeb.Endpoint`のエイリアスを忘れないようにしましょう。

```elixir
iex> alias HelloWeb.Endpoint
iex> HelloWeb.Router.Helpers.user_post_path(Endpoint, :show, 42, 17)
"/users/42/posts/17"
```

繰り返しになりますが、関数呼び出しの最後にキーと値のペアを追加すると、それがクエリ文字列に追加されます。

```elixir
iex> HelloWeb.Router.Helpers.user_post_path(Endpoint, :index, 42, active: true)
"/users/42/posts?active=true"
```

以前のように`Helpers`モジュールをエイリアスしていれば（ビュー、テンプレート、コントローラーに対してのみ自動的にエイリアスされますが、この場合は`iex`の中にいるので自分たちでエイリアスする必要があります）、代わりに次のように記述できます。

```elixir
iex> alias HelloWeb.Router.Helpers, as: Routes
iex> alias HelloWeb.Endpoint
iex> Routes.user_post_path(Endpoint, :index, 42, active: true)
"/users/42/posts?active=true"
```

## スコープされたルート

スコープは、共通のパスのプレフィックスと一連のplugを元にルートをグループ化する方法です。管理者機能やAPI、とくにバージョン管理されたAPIのためにこれを行いたいと思うかもしれません。あるサイトにユーザーが生成したレビューがあり、それらのレビューはまず管理者によって承認される必要があるとしましょう。これらのリソースの意味合いはまったく異なり、同じコントローラーを共有しているわけではないかもしれません。スコープはこれらのルートを分離することを可能にします。

ユーザー向けのレビューへのパスは標準的なリソースのように見えます。

```console
/reviews
/reviews/1234
/reviews/1234/edit
...
```

管理者レビューのパスの前には`/admin`をつけることができます。

```console
/admin/reviews
/admin/reviews/1234
/admin/reviews/1234/edit
...
```

これは、このように`/admin`にパスオプションを設定するスコープ付きルートを使って実現します。 今のところ、このスコープを他のスコープの中に入れ子にしないようにしましょう（新しいアプリで提供されている`scope "/", HelloWeb do`のように）。

```elixir
scope "/admin" do
  pipe_through :browser

  resources "/reviews", HelloWeb.Admin.ReviewController
end
```

また、現在このスコープが定義されている方法では、コントローラー名を`HelloWeb.Admin.ReviewController`のように修正する必要があることにも注意してください。 これはすぐに修正します。

もう一度`mix phx.routes`を実行すると、以前のルートに加えて以下のようになります。

```elixir
...
review_path  GET     /admin/reviews           HelloWeb.Admin.ReviewController :index
review_path  GET     /admin/reviews/:id/edit  HelloWeb.Admin.ReviewController :edit
review_path  GET     /admin/reviews/new       HelloWeb.Admin.ReviewController :new
review_path  GET     /admin/reviews/:id       HelloWeb.Admin.ReviewController :show
review_path  POST    /admin/reviews           HelloWeb.Admin.ReviewController :create
review_path  PATCH   /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
             PUT     /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
review_path  DELETE  /admin/reviews/:id       HelloWeb.Admin.ReviewController :delete
```

これは一見すると良さそうに見えますが、ここで問題があります。私たちは管理者用のもの`/admin/reviews`だけでなく、ユーザーに向けたレビュールート`/reviews`も欲しかったのでした。ユーザー向けのレビュールートを含めるとすると、ルーターは次のようになります。

```elixir
scope "/", HelloWeb do
  pipe_through :browser
  ...
  resources "/reviews", ReviewController
  ...
end

scope "/admin" do
  resources "/reviews", HelloWeb.Admin.ReviewController
end
```

そして`mix phx.routes`を実行すると、このような出力が得られます。

```elixir
...
review_path  GET     /reviews                 HelloWeb.ReviewController :index
review_path  GET     /reviews/:id/edit        HelloWeb.ReviewController :edit
review_path  GET     /reviews/new             HelloWeb.ReviewController :new
review_path  GET     /reviews/:id             HelloWeb.ReviewController :show
review_path  POST    /reviews                 HelloWeb.ReviewController :create
review_path  PATCH   /reviews/:id             HelloWeb.ReviewController :update
             PUT     /reviews/:id             HelloWeb.ReviewController :update
review_path  DELETE  /reviews/:id             HelloWeb.ReviewController :delete
...
review_path  GET     /admin/reviews           HelloWeb.Admin.ReviewController :index
review_path  GET     /admin/reviews/:id/edit  HelloWeb.Admin.ReviewController :edit
review_path  GET     /admin/reviews/new       HelloWeb.Admin.ReviewController :new
review_path  GET     /admin/reviews/:id       HelloWeb.Admin.ReviewController :show
review_path  POST    /admin/reviews           HelloWeb.Admin.ReviewController :create
review_path  PATCH   /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
             PUT     /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
review_path  DELETE  /admin/reviews/:id       HelloWeb.Admin.ReviewController :delete
```

実際のルートは、各行の先頭にあるパスヘルパー`review_path`を除いて、すべて正しく見えます。ユーザーが利用するレビュールートと管理者が利用するレビュールートの両方で同じヘルパーを取得していますが、これは正しくありません。この問題は、adminスコープに`as: :admin`オプションを追加することで解決できます。

```elixir
scope "/", HelloWeb do
  pipe_through :browser
  ...
  resources "/reviews", ReviewController
  ...
end

scope "/admin", as: :admin do
  resources "/reviews", HelloWeb.Admin.ReviewController
end
```

これで、`mix phx.routes`は期待した結果になります。

```elixir
...
      review_path  GET     /reviews                        HelloWeb.ReviewController :index
      review_path  GET     /reviews/:id/edit               HelloWeb.ReviewController :edit
      review_path  GET     /reviews/new                    HelloWeb.ReviewController :new
      review_path  GET     /reviews/:id                    HelloWeb.ReviewController :show
      review_path  POST    /reviews                        HelloWeb.ReviewController :create
      review_path  PATCH   /reviews/:id                    HelloWeb.ReviewController :update
                   PUT     /reviews/:id                    HelloWeb.ReviewController :update
      review_path  DELETE  /reviews/:id                    HelloWeb.ReviewController :delete
...
admin_review_path  GET     /admin/reviews                  HelloWeb.Admin.ReviewController :index
admin_review_path  GET     /admin/reviews/:id/edit         HelloWeb.Admin.ReviewController :edit
admin_review_path  GET     /admin/reviews/new              HelloWeb.Admin.ReviewController :new
admin_review_path  GET     /admin/reviews/:id              HelloWeb.Admin.ReviewController :show
admin_review_path  POST    /admin/reviews                  HelloWeb.Admin.ReviewController :create
admin_review_path  PATCH   /admin/reviews/:id              HelloWeb.Admin.ReviewController :update
                   PUT     /admin/reviews/:id              HelloWeb.Admin.ReviewController :update
admin_review_path  DELETE  /admin/reviews/:id              HelloWeb.Admin.ReviewController :delete
```

パスヘルパーは、私たちが望むものを返すようになりました。これを自分で試してみてください。

```elixir
iex(1)> HelloWeb.Router.Helpers.review_path(HelloWeb.Endpoint, :index)
"/reviews"

iex(2)> HelloWeb.Router.Helpers.admin_review_path(HelloWeb.Endpoint, :show, 1234)
"/admin/reviews/1234"
```

複数のリソースを管理者がすべて処理するとしたらどうでしょうか？このようにすべてのリソースを同じスコープ内に置くことができます。

```elixir
scope "/admin", as: :admin do
  pipe_through :browser

  resources "/images",  HelloWeb.Admin.ImageController
  resources "/reviews", HelloWeb.Admin.ReviewController
  resources "/users",   HelloWeb.Admin.UserController
end
```

以下に、`mix phx.routes`の結果を示します。

```elixir
...
 admin_image_path  GET     /admin/images            HelloWeb.Admin.ImageController :index
 admin_image_path  GET     /admin/images/:id/edit   HelloWeb.Admin.ImageController :edit
 admin_image_path  GET     /admin/images/new        HelloWeb.Admin.ImageController :new
 admin_image_path  GET     /admin/images/:id        HelloWeb.Admin.ImageController :show
 admin_image_path  POST    /admin/images            HelloWeb.Admin.ImageController :create
 admin_image_path  PATCH   /admin/images/:id        HelloWeb.Admin.ImageController :update
                   PUT     /admin/images/:id        HelloWeb.Admin.ImageController :update
 admin_image_path  DELETE  /admin/images/:id        HelloWeb.Admin.ImageController :delete
admin_review_path  GET     /admin/reviews           HelloWeb.Admin.ReviewController :index
admin_review_path  GET     /admin/reviews/:id/edit  HelloWeb.Admin.ReviewController :edit
admin_review_path  GET     /admin/reviews/new       HelloWeb.Admin.ReviewController :new
admin_review_path  GET     /admin/reviews/:id       HelloWeb.Admin.ReviewController :show
admin_review_path  POST    /admin/reviews           HelloWeb.Admin.ReviewController :create
admin_review_path  PATCH   /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
                   PUT     /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
admin_review_path  DELETE  /admin/reviews/:id       HelloWeb.Admin.ReviewController :delete
  admin_user_path  GET     /admin/users             HelloWeb.Admin.UserController :index
  admin_user_path  GET     /admin/users/:id/edit    HelloWeb.Admin.UserController :edit
  admin_user_path  GET     /admin/users/new         HelloWeb.Admin.UserController :new
  admin_user_path  GET     /admin/users/:id         HelloWeb.Admin.UserController :show
  admin_user_path  POST    /admin/users             HelloWeb.Admin.UserController :create
  admin_user_path  PATCH   /admin/users/:id         HelloWeb.Admin.UserController :update
                   PUT     /admin/users/:id         HelloWeb.Admin.UserController :update
  admin_user_path  DELETE  /admin/users/:id         HelloWeb.Admin.UserController :delete
```

これは素晴らしいことで、まさに私たちが望んでいることですが、もっと良いものを作ることができます。各リソースに対して、コントローラー名の前に`HelloWeb.Admin`をつけて完全に修飾する必要があることに注目してください。これは面倒でエラーが発生しやすいです。各コントローラーの名前が`HelloWeb.Admin`で始まると仮定すると、スコープパスの直後のスコープ宣言に`HelloWeb.Admin`オプションを追加すれば、すべてのルートは正しい、完全修飾されたコントローラー名を持つことになります。

```elixir
scope "/admin", HelloWeb.Admin, as: :admin do
  pipe_through :browser

  resources "/images",  ImageController
  resources "/reviews", ReviewController
  resources "/users",   UserController
end
```

もう一度`mix phx.routes`を実行してみると、各コントローラー名を個別に修飾した場合と同じ結果が得られることがわかります。

これはネストされたルートだけに適用されるわけではありません。アプリケーションのすべてのルートをネスティングして、Phoenixアプリの名前のエイリアスを持つスコープの中に入れて、コントローラー名の中のアプリケーション名の重複を排除することもできます。

Phoenixは、新しいアプリケーション用に生成されたルーターの中ですでにこれを行っています（このセクションの最初の方を参照してください）。ここでは、`scope`宣言の中で`HelloWeb`を使用していることに注目してください。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  scope "/", HelloWeb do
    pipe_through :browser

    get "/images", ImageController, :index
    resources "/reviews", ReviewController
    resources "/users",   UserController
  end
end
```

再び`mix phx.routes`を実行すると、すべてのコントローラーが正しい完全修飾名を持つようになったことを教えてくれます。

```elixir
 image_path  GET     /images            HelloWeb.ImageController :index
review_path  GET     /reviews           HelloWeb.ReviewController :index
review_path  GET     /reviews/:id/edit  HelloWeb.ReviewController :edit
review_path  GET     /reviews/new       HelloWeb.ReviewController :new
review_path  GET     /reviews/:id       HelloWeb.ReviewController :show
review_path  POST    /reviews           HelloWeb.ReviewController :create
review_path  PATCH   /reviews/:id       HelloWeb.ReviewController :update
             PUT     /reviews/:id       HelloWeb.ReviewController :update
review_path  DELETE  /reviews/:id       HelloWeb.ReviewController :delete
  user_path  GET     /users             HelloWeb.UserController :index
  user_path  GET     /users/:id/edit    HelloWeb.UserController :edit
  user_path  GET     /users/new         HelloWeb.UserController :new
  user_path  GET     /users/:id         HelloWeb.UserController :show
  user_path  POST    /users             HelloWeb.UserController :create
  user_path  PATCH   /users/:id         HelloWeb.UserController :update
             PUT     /users/:id         HelloWeb.UserController :update
  user_path  DELETE  /users/:id         HelloWeb.UserController :delete
```

技術的にはスコープは入れ子にすることもできますが（リソースと同じように）、入れ子にしたスコープを使用することはコードを紛らわしく複雑にすることがあるので、一般的にはオススメできません。とはいえ、画像、レビュー、ユーザー用のリソースを定義したバージョン管理されたAPIがあったとしましょう。その場合、技術的には以下のようにバージョニングされたAPIのルートを設定できます。

```elixir
scope "/api", HelloWeb.Api, as: :api do
  pipe_through :api

  scope "/v1", V1, as: :v1 do
    resources "/images",  ImageController
    resources "/reviews", ReviewController
    resources "/users",   UserController
  end
end
```

`mix phx.routes`は、探しているルートを持っていることを教えてくれます。 

```elixir
 api_v1_image_path  GET     /api/v1/images            HelloWeb.Api.V1.ImageController :index
 api_v1_image_path  GET     /api/v1/images/:id/edit   HelloWeb.Api.V1.ImageController :edit
 api_v1_image_path  GET     /api/v1/images/new        HelloWeb.Api.V1.ImageController :new
 api_v1_image_path  GET     /api/v1/images/:id        HelloWeb.Api.V1.ImageController :show
 api_v1_image_path  POST    /api/v1/images            HelloWeb.Api.V1.ImageController :create
 api_v1_image_path  PATCH   /api/v1/images/:id        HelloWeb.Api.V1.ImageController :update
                    PUT     /api/v1/images/:id        HelloWeb.Api.V1.ImageController :update
 api_v1_image_path  DELETE  /api/v1/images/:id        HelloWeb.Api.V1.ImageController :delete
api_v1_review_path  GET     /api/v1/reviews           HelloWeb.Api.V1.ReviewController :index
api_v1_review_path  GET     /api/v1/reviews/:id/edit  HelloWeb.Api.V1.ReviewController :edit
api_v1_review_path  GET     /api/v1/reviews/new       HelloWeb.Api.V1.ReviewController :new
api_v1_review_path  GET     /api/v1/reviews/:id       HelloWeb.Api.V1.ReviewController :show
api_v1_review_path  POST    /api/v1/reviews           HelloWeb.Api.V1.ReviewController :create
api_v1_review_path  PATCH   /api/v1/reviews/:id       HelloWeb.Api.V1.ReviewController :update
                    PUT     /api/v1/reviews/:id       HelloWeb.Api.V1.ReviewController :update
api_v1_review_path  DELETE  /api/v1/reviews/:id       HelloWeb.Api.V1.ReviewController :delete
  api_v1_user_path  GET     /api/v1/users             HelloWeb.Api.V1.UserController :index
  api_v1_user_path  GET     /api/v1/users/:id/edit    HelloWeb.Api.V1.UserController :edit
  api_v1_user_path  GET     /api/v1/users/new         HelloWeb.Api.V1.UserController :new
  api_v1_user_path  GET     /api/v1/users/:id         HelloWeb.Api.V1.UserController :show
  api_v1_user_path  POST    /api/v1/users             HelloWeb.Api.V1.UserController :create
  api_v1_user_path  PATCH   /api/v1/users/:id         HelloWeb.Api.V1.UserController :update
                    PUT     /api/v1/users/:id         HelloWeb.Api.V1.UserController :update
  api_v1_user_path  DELETE  /api/v1/users/:id         HelloWeb.Api.V1.UserController :delete
```

興味深いことに、ルートが重複しないように注意していれば、同じパスで複数のスコープを使用できます。もしルートを複製してしまうと、おなじみの警告が表示されます。

```console
warning: this clause cannot match because a previous clause at line 16 always matches
```

このルーターは、同じパスに2つのスコープが定義されていても全く問題ありません。

```elixir
defmodule HelloWeb.Router do
  use Phoenix.Router
  ...
  scope "/", HelloWeb do
    pipe_through :browser

    resources "/users", UserController
  end

  scope "/", AnotherAppWeb do
    pipe_through :browser

    resources "/posts", PostController
  end
  ...
end
```

そして、`mix phx.routes`を実行すると、以下のような出力が出てきます。

```elixir
user_path  GET     /users           HelloWeb.UserController :index
user_path  GET     /users/:id/edit  HelloWeb.UserController :edit
user_path  GET     /users/new       HelloWeb.UserController :new
user_path  GET     /users/:id       HelloWeb.UserController :show
user_path  POST    /users           HelloWeb.UserController :create
user_path  PATCH   /users/:id       HelloWeb.UserController :update
           PUT     /users/:id       HelloWeb.UserController :update
user_path  DELETE  /users/:id       HelloWeb.UserController :delete
post_path  GET     /posts           AnotherAppWeb.PostController :index
post_path  GET     /posts/:id/edit  AnotherAppWeb.PostController :edit
post_path  GET     /posts/new       AnotherAppWeb.PostController :new
post_path  GET     /posts/:id       AnotherAppWeb.PostController :show
post_path  POST    /posts           AnotherAppWeb.PostController :create
post_path  PATCH   /posts/:id       AnotherAppWeb.PostController :update
           PUT     /posts/:id       AnotherAppWeb.PostController :update
post_path  DELETE  /posts/:id       AnotherAppWeb.PostController :delete
```

## パイプライン

ルーターで最初に見た行の一つである`pipe_through :browser`について語らずに、このガイドではかなり長い道のりを歩んできました。それを語るときがきました。

[概要ガイド](./introduction/overview.html)で、プラグをパイプラインのようにあらかじめ決められた順番でスタックされて実行可能なものだと説明したのを覚えていますか？ここでは、これらのプラグスタックがルーター内でどのように機能するのかを詳しく見ていきましょう。

パイプラインとは、単純にプラグを特定の順番で積み上げて名前を付けたものです。これにより、リクエストの処理に関連した動作や変換をカスタマイズできます。Phoenixは、いくつかの一般的なタスク用のデフォルトのパイプラインを提供しています。必要に応じてパイプラインをカスタマイズしたり、新しいパイプラインを作成したりできます。

新しく生成されたPhoenixアプリケーションでは、`:browser`と`:api`という2つのパイプラインを定義しています。これらについてはすぐに説明しますが、まず、Endpoint plugs のプラグスタックについて説明します。

### エンドポイントプラグ

エンドポイントはすべてのリクエストに共通するすべてのプラグを整理し、それらをルーターにディスパッチする前に適用します。デフォルトのEndpointプラグはかなり多くの作業を行います。ここでは順を追って説明します。

- [Plug.Static](https://hexdocs.pm/plug/Plug.Static.html) - 静的なアセットを提供します。このプラグはロガーの前に来るので、静的アセットの提供はログに記録されません。

- [Phoenix.CodeReloader](https://hexdocs.pm/phoenix/Phoenix.CodeReloader.html) - ウェブディレクトリ内のすべてのエントリのコードのリロードを可能にするプラグです。Phoenixアプリケーションで直接設定します。

- [Plug.RequestId](https://hexdocs.pm/plug/Plug.RequestId.html) - 各リクエストに対して一意のリクエストIDを生成します。

- [Plug.Logger](https://hexdocs.pm/plug/Plug.Logger.html) - 受信したリクエストをログに記録します。

- [Plug.Parsers](https://hexdocs.pm/plug/Plug.Parsers.html) - 既知のパーサーが利用可能な場合に、リクエストボディを解析します。デフォルトでは、パーサーは urlencoded, multipart, json（with `jason`）をパースします。リクエストのcontent-typeが解析できない場合、リクエストボディはそのままになります。

- [Plug.MethodOverride](https://hexdocs.pm/plug/Plug.MethodOverride.html) - 有効な`_method`パラメータを持つPOSTリクエストのリクエストメソッドをPUT、PATCH、DELETEに変換します。

- [Plug.Head](https://hexdocs.pm/plug/Plug.Head.html) - HEADリクエストをGETリクエストに変換し、レスポンスボディを削除します。

- [Plug.Session](https://hexdocs.pm/plug/Plug.Session.html) - セッション管理を設定するプラグインです。
  このプラグインはセッションの取得方法を設定するだけなので、`fetch_session/2`はセッションを使う前に明示的に呼ばれなければならないことに注意してください。

- [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html) - ルーターをリクエストサイクルに接続します。

### `:browser`と`:api`パイプライン

Phoenixはデフォルトで他の2つのパイプライン`:browser`と`:api`を定義しています。それらを囲んでいるスコープで`pipe_through/1`を呼び出していると仮定すると、ルーターはルートにマッチした後にこれらのパイプラインを呼び出します。

その名が示すように、`:browser`パイプラインはブラウザへのリクエストをレンダリングするルートの準備をします。`:api`パイプラインはapiのデータを生成するルートの準備をします。

`:browser`パイプラインには5つのプラグがあります: 受け入れられるリクエストフォーマットを定義する`plug :accepts, ["html"]`、セッションデータを取得してコネクション内で利用可能にする`:fetch_session`、設定されている可能性のあるフラッシュメッセージを取得する`:fetch_flash`、そしてフォーム投稿をクロスサイトフォージェリから保護する`:protect_from_forgery`と`:put_secure_browser_headers`があります。

現在のところ、`:api`パイプラインは`plug :accepts, ["json"]`しか定義していません。

ルーターはスコープ内で定義されたルート上でパイプラインを起動します。スコープが定義されていない場合、ルーターはルーター内のすべてのルートでパイプラインを呼び出します。入れ子になったスコープの使用はオススメしませんが (上記参照)、もし入れ子になったスコープの中で`pipe_through`を呼び出すと、ルーターは親スコープからすべての`pipe_through`を呼び出し、その後に入れ子になったスコープを呼び出します。

これらの単語はたくさんの単語を束ねています。その意味を理解するために、いくつかの例を見てみましょう。

新しく生成されたPhoenixアプリケーションからルーターを見てみましょう。今回は、apiスコープのコメントを外して、ルートを追加しました。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", HelloWeb do
    pipe_through :api

    resources "/reviews", ReviewController
  end
end
```

サーバーがリクエストを受け入れるとき、リクエストは常に最初にEndpointのプラグを通過し、その後、パスとHTTPメソッドにマッチしようとします。

リクエストが最初のルートであるGET `/`にマッチしたとしましょう。ルーターはまずそのリクエストを`PageController` `index` アクションへディスパッチする前に`:browser`パイプラインを経由してパイプし、セッションデータの取得、フラッシュの取得、クロスサイトリクエストフォージェリ対策を行います。

逆に、リクエストが`resources/2`マクロで定義されたルートのいずれかにマッチした場合、ルーターは`:api`パイプライン（現在は何もしていません）を通ってリクエストをパイプし、`HelloWeb.ReviewController`の正しいアクションにディスパッチします。

アプリケーションがブラウザ用のビューしかレンダリングしないことがわかっていれば、スコープと同様に`api`スコープを取り除くことで、ルーターをかなり単純化できます。


```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipe_through :browser

  get "/", HelloWeb.PageController, :index

  resources "/reviews", HelloWeb.ReviewController
end
```

すべてのスコープを削除すると、ルーターはすべてのルートで`:browser`パイプラインを強制的に呼び出します。

これらの考えをもう少し広げてみましょう。リクエストを`:browser`と1つ以上のカスタムパイプラインの両方にパイプする必要がある場合はどうでしょうか？単純にパイプラインのリストをパイプスルーするだけで、Phoenixはそれらのパイプラインを順番に起動します。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  ...

  scope "/reviews" do
    pipe_through [:browser, :review_checks, :other_great_stuff]

    resources "/", HelloWeb.ReviewController
  end
end
```

ここでは、異なるパイプラインを持つ2つのスコープの例を示します。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  ...

  scope "/", HelloWeb do
    pipe_through :browser

    resources "/posts", PostController
  end

  scope "/reviews", HelloWeb do
    pipe_through [:browser, :review_checks]

    resources "/", ReviewController
  end
end
```

一般的に、パイプラインのスコープルールは期待通りに動作します。この例では、すべてのルートは`:browser`パイプラインを通過します。しかし、`reviews`のresourcesルートだけが`:review_checks`パイプラインを通過します。`pipe_through [:browser, :review_checks]`で両方のパイプをリストで宣言しているので、Phoenixはそれらを順番に呼び出し、それぞれのパイプを`pipe_through`します。

### 新しいパイプラインの作成

Phoenixでは、ルーター内の任意の場所に独自のパイプラインを作成できます。これを行うには、`pipeline/2`マクロをこれらの引数で呼び出します。これらの2つの引数は、新しいパイプラインの名前のためのatomと実行したいすべてのプラグをもったブロックです。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :review_checks do
    plug :ensure_authenticated_user
    plug :ensure_user_owns_review
  end

  scope "/reviews", HelloWeb do
    pipe_through :review_checks

    resources "/", ReviewController
  end
end
```

## チャネルルート

チャネルは、Phoenixフレームワークの非常にエキサイティングなリアルタイムコンポーネントです。チャネルは、特定のトピックのソケットを介してブロードキャストされた受信メッセージと送信メッセージを処理します。チャネルルートは、正しいチャネルにディスパッチするために、ソケットによるリクエストとトピックを一致させる必要があります。(チャネルとその動作の詳細については、[チャネルガイド](channels.html) を参照してください)。

ソケットハンドラはエンドポイントの`lib/hello_web/endpoint.ex`にマウントします。ソケットハンドラは認証のコールバックとチャネルのルートを管理します。

```elixir
defmodule HelloWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :hello

  socket "/socket", HelloWeb.UserSocket,
    websocket: true,
    longpoll: false
  ...
end
```

デフォルトでは、エンドポイントで`Phoenix.Endpoint.socket/3`を呼び出すと、PhoenixはWebSocketとlongpollの両方をサポートします。 ここでは、受信するソケット接続をWebSocket接続で行うように指定しています。

次に、`lib/hello_web/channels/user_socket.ex`ファイルを開き、`channel/3`マクロを使用してチャネルルートを定義する必要があります。 このルートは、イベントを処理するためにトピックパターンをチャネルにマッチさせます。もし、`RoomChannel`というチャネルモジュールと`"rooms:*"`というトピックがあれば、これを行うコードは簡単です。

```elixir
defmodule HelloWeb.UserSocket do
  use Phoenix.Socket

  channel "rooms:*", HelloWeb.RoomChannel
  ...
end
```

トピックは単なる文字列の識別子です。ここで使用している形式（"topic:subtopic"）は、トピックとサブトピックを同じ文字列で定義できるようにするための慣例です。`*`はワイルドカード文字で、任意のサブトピックにマッチさせることができます。
したがって、`"room:lobby"` と `"room:kitchen"` はどちらもこのルートにマッチします。

各ソケットは複数のチャネルのリクエストを扱うことができます。

```elixir
channel "rooms:*", HelloWeb.RoomChannel
channel "foods:*", HelloWeb.FoodChannel
```

エンドポイントに複数のソケットハンドラをマウントすることもできます。

```elixir
socket "/socket", HelloWeb.UserSocket
socket "/admin-socket", HelloWeb.AdminSocket
```

## まとめ

ルーティングは大きなトピックであり、ここでは多くの分野をカバーしています。このガイドから取り上げる重要なポイントは以下の通りです。
- HTTPメソッド名で始まるルートは、1つのmatch関数定義まで拡張されます。
- `resources`で始まるルートは、8つのmatch関数定義まで拡張されます。
- リソースは、`only:`または`except:`オプションを使用して、match関数の数を制限できます。
- これらのルートはいずれも入れ子にできます。
- これらのルートはいずれも、指定したパスにスコープできます。
- スコープで`as:`オプションを使用すると重複を減らすことができます。
- スコープされたルートにヘルパーオプションを使用すると、到達不可能なパスを排除できます。
