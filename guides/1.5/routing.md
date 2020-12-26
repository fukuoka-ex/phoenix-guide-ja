---
layout: 1.5/layout
version: 1.5
group: guides
title: ルーティング
nav_order: 4
hash: 464192b4
---
# ルーティング

> **前提**:  このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: [リクエストのライフサイクルガイド](request_lifecycle.html)を理解していることを前提としています

ルーターは、Phoenixアプリケーションのメインハブです。ルーターは、HTTPリクエストをコントローラーアクションにマッチさせ、リアルタイムチャネルハンドラをつなぎ、一連のパイプライン変換を一連のルートにスコープして定義します。

Phoenixが生成するルーターファイル `lib/hello_web/router.ex` は以下のようになります。

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

ルーター名とコントローラーモジュール名の両方とも、`HelloWeb`ではなく、アプリケーションに与えた名前がプレフィックスになります。

このモジュールの最初の行である `use HelloWeb, : router` は、Phoenixルーターの関数をルーターで利用できるようにするだけです。

スコープはこのガイドでは独自のセクションを持っているので、ここでは `scope "/", HelloWeb do` のブロックの説明は割愛します。`pipe_through :browser` 行については、このガイドのパイプラインのセクションで詳しく説明します。今のところ、パイプラインでは一連のプラグを異なるルートのセットに適用することができるということだけは知っておく必要があります。

スコープブロックの中には、最初の実際のルートがあります。

```elixir
get "/", PageController, :index
```

`get`はHTTP動詞のGETに対応するPhoenixマクロです。同様のマクロは、POST、PUT、PATCH、DELETE、OPTIONS、CONNECT、TRACE、HEADなどの他のHTTP動詞にも存在します。

## ルートを調べる

Phoenixはアプリケーション内のルートを調査するための素晴らしいツールを提供しています: `mix phx.routes`.

これがどのように動作するか見てみましょう。新しく生成されたPhoenixアプリケーションのルートに行き、`mix phx.routes` を実行してください。次のような、生成されたすべてのルートが確認できます。

```console
$ mix phx.routes
page_path  GET  /  HelloWeb.PageController :index
```

上のルートは、アプリケーションのルートに対するHTTP GETリクエストが `HelloWeb.PageController` の `index` アクションによって処理されることを示しています。

`page_path`はPhoenixがパスヘルパーと呼ぶものの例です。これらは後ほど説明します。

## リソース

ルーターは `get`, `post`, `put` などのHTTP動詞以外にもマクロをサポートしています。その中でもとくに重要なのは `resources` です。次のように`lib/hello_web/router.ex` ファイルにリソースを追加してみましょう。

```elixir
scope "/", HelloWeb do
  pipe_through :browser

  get "/", PageController, :index
  resources "/users", UserController
end
```

今のところ、実際に `HelloWeb.UserController` を持っていないことは問題ではありません。

プロジェクトのルートでもう一度 `mix phx.routes` を実行してください。以下のようなものが表示されるはずです。

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

これは、HTTP動詞、パス、コントローラーのアクションの標準的な行列です。しばらくの間、これはRESTful routesとして知られていましたが、現在ではほとんどの人がこれを誤記と考えています。少し順番を変えて、個別に見ていきましょう。

- `/users` へのGETリクエストは `index` アクションを呼び出し、すべてのユーザーを表示します。
- `/users/new` へのGETリクエストは `new` アクションを呼び出し、新しいユーザーを作成するためのフォームを表示します。
- `/users/:id` へのGETリクエストは、idを指定して `show` アクションを呼び出し、そのIDで識別される個々のユーザーを表示します。
- `/user` へのPOSTリクエストは `create` アクションを呼び出し、新しいユーザーをデータストアに保存します。
- `/users/:id/edit` へのGETリクエストは、IDを指定して `edit` アクションを呼び出し、データストアから個々のユーザーを取得して編集用のフォームで情報を表示します。
- `/users/:id` へのPATCHリクエストは、IDを指定して `update` アクションを呼び出し、更新されたユーザーをデータストアに保存します。
- `/users/:id` へのPUTリクエストもまた `update` アクションを呼び出し、IDを指定して更新されたユーザーをデータストアに保存する。
- `/users/:id` へのDELETEリクエストは、IDを指定して `delete` アクションを呼び出し、個々のユーザーをデータストアから削除します。

これらのルートをすべて必要としない場合は、`:only` と `:except` オプションを使って特定のアクションをフィルタリングできます。

読み取り専用の投稿リソースがあるとしましょう。このように定義できます。

```elixir
resources "/posts", PostController, only: [:index, :show]
```

`mix phx.routes` を実行すると、indexとshowアクションへのルートだけが定義されていることがわかります。

```elixir
post_path  GET     /posts      HelloWeb.PostController :index
post_path  GET     /posts/:id  HelloWeb.PostController :show
```

同様に、コメントリソースがあり、そのリソースを削除するためのルートを提供したくない場合、次のように定義できます。

```elixir
resources "/comments", CommentController, except: [:delete]
```

これで `mix phx.routes` を実行すると、削除アクションへのDELETEリクエストを除くすべてのルートがあることがわかります。

```elixir
comment_path  GET    /comments           HelloWeb.CommentController :index
comment_path  GET    /comments/:id/edit  HelloWeb.CommentController :edit
comment_path  GET    /comments/new       HelloWeb.CommentController :new
comment_path  GET    /comments/:id       HelloWeb.CommentController :show
comment_path  POST   /comments           HelloWeb.CommentController :create
comment_path  PATCH  /comments/:id       HelloWeb.CommentController :update
              PUT    /comments/:id       HelloWeb.CommentController :update
```

`Phoenix.Router.resources/4` マクロは、リソースルートをカスタマイズするための追加オプションを記述します。

## パスヘルパー

パスヘルパーは、個々のアプリケーションのために `Router.Helpers` モジュール上で動的に定義される関数です。私たちの場合、それは `HelloWeb.Router.Helpers` です。各パスヘルパーの名前は、ルート定義で使用されるコントローラーの名前に由来します。コントローラーは `HelloWeb.PageController` で、`page_path` はアプリケーションのルートへのパスを返す関数です。

一言では言えないですね。実際に見てみましょう。プロジェクトのルートで `iex -S mix` を実行します。ルーターヘルパーの `page_path` 関数を `Endpoint` あるいは接続とアクションを引数に指定して呼び出すと、パスを返してくれます。

```elixir
iex> HelloWeb.Router.Helpers.page_path(HelloWeb.Endpoint, :index)
"/"
```

テンプレート内で `page_path` 関数を使用してアプリケーションのルートにリンクすることができるので、これは重要です。テンプレートの中でこのヘルパーを使うことができます。

```html
<%= link "Welcome Page!", to: Routes.page_path(@conn, :index) %>
```

完全な `HelloWeb.Router.Helpers.page_path` の代わりに `Routes.page_path` を使用できるのは、`HelloWeb.Router.Helpers` はデフォルトで `lib/hello_web.ex` 内の `view/0` ブロックで `Routes` としてエイリアスされているからです。この定義は、`use HelloWeb, :view`によってテンプレートで利用できるようになっています。

もちろん、代わりに `HelloWeb.Router.Helpers.page_path(@conn, :index)` を使うこともできますが、簡潔さのためにエイリアス版を使うのが慣例です。エイリアスは、ビュー、コントローラー、テンプレートで使用するためだけに自動的に設定されることに注意してください - これらの外では、フルネームか、モジュール定義の中で `alias HelloWeb.Router.Helpers, as.Routes`でモジュール定義の中で自分でエイリアスを設定する必要があります。

パスヘルパーを使用することで、コントローラー、ビュー、テンプレートがルーターが実際に処理できるページにリンクしていることを簡単に保証できます。

### パスヘルパーの詳細

ユーザーリソースに対して `mix phx.routes` を実行すると、出力の各行のパスヘルパー関数として `user_path` がリストアップされます。これはそれぞれのアクションのために翻訳されています。

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

クエリストリングを持つパスはどうでしょうか？オプションの第4引数にkey-valueのペアを追加することで、パスヘルパーはクエリ文字列のペアを返します。

```elixir
iex> Routes.user_path(Endpoint, :show, 17, admin: true, active: false)
"/users/17?admin=true&active=false"
```

パスの代わりに完全なURLが必要な場合はどうすればよいでしょうか？`_path` を `_url` に置き換えるだけです。

```elixir
iex(3)> Routes.user_url(Endpoint, :index)
"http://localhost:4000/users"
```

`_url` 関数は、環境ごとに設定されたconfigurationから、完全なURLを構築するために必要なホスト、ポート、プロキシポート、SSLの情報を取得します。configurationについては、それ自身のガイドで詳しく説明します。とりあえず、自分のプロジェクトの `config/dev.exs` ファイルを見て、これらの値を確認できます。

可能な限り、`Endpoint` の代わりに `conn` (ビューでは `@conn`) を渡すことをオススメします。

## 入れ子になったリソース

Phoenixルーターの中にリソースをネストすることも可能です。たとえば、`users`と多対1の関係にある`posts`リソースがあるとしましょう。つまり、1人のユーザーが多くの投稿を作成することができ、個々の投稿は1人のユーザーにしか属していないということです。これを表現するには、`lib/hello_web/router.ex` に次のようなネストされたルートを追加します。

```elixir
resources "/users", UserController do
  resources "/posts", PostController
end
```
上で見た `users` 用のルートに加えて、`mix phx.routes` を実行すると、以下のようなルートが得られます。

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

これらのルートのそれぞれがpostをユーザーIDにスコープしていることがわかります。最初のルートでは、`PostController` `index` アクションを呼び出しますが、`user_id` を渡します。これは、そのユーザーのすべての投稿を表示することを意味します。これらすべてのルートに同じスコープが適用されます。

ネストしたルートに対してパスヘルパー関数を呼び出す際には、ルート定義で指定した順番でIDを渡す必要があります。次の `show` ルートでは、`42` が `user_id` で、`17` が `post_id` です。始める前に、`HelloWeb.Endpoint`のエイリアスを忘れないようにしましょう。

```elixir
iex> alias HelloWeb.Endpoint
iex> HelloWeb.Router.Helpers.user_post_path(Endpoint, :show, 42, 17)
"/users/42/posts/17"
```

ここでも、関数呼び出しの最後にkey-valueのペアを追加すると、それがクエリ文字列に追加されます。

```elixir
iex> HelloWeb.Router.Helpers.user_post_path(Endpoint, :index, 42, active: true)
"/users/42/posts?active=true"
```

`Helpers` モジュールをエイリアスしていれば（ビュー、テンプレート、コントローラーに対してのみ自動的にエイリアスされますが、この場合は `iex` の中にいるので自分でエイリアスする必要があります）、代わりに次のようにできます。

```elixir
iex> alias HelloWeb.Router.Helpers, as: Routes
iex> alias HelloWeb.Endpoint
iex> Routes.user_post_path(Endpoint, :index, 42, active: true)
"/users/42/posts?active=true"
```

## スコープされたルート

スコープは、共通のパスプレフィックスとスコープされた一連のプラグの下でルートをグループ化する方法です。これは、管理者機能やAPI、特にバージョン管理されたAPIのために必要になるかもしれません。あるサイトにユーザーが生成したレビューがあり、それらのレビューは最初に管理者によって承認される必要があるとしましょう。これらのリソースのセマンティクスはまったく異なり、同じコントローラーを共有しているわけではないかもしれません。スコープを使用することで、これらのルートを分離できます。

ユーザーが利用するレビューへのパスは、標準的なリソースのように見えるでしょう。

```console
/reviews
/reviews/1234
/reviews/1234/edit
...
```

管理者レビューのパスの前に `/admin` をつけることができます。

```console
/admin/reviews
/admin/reviews/1234
/admin/reviews/1234/edit
...
```

これを実現するには、このように `/admin` にパスオプションを設定するスコープ付きルートを使用します。このスコープを別のスコープの中に入れ子にすることもできますが、その代わりにルートにスコープを設定しましょう。

```elixir
scope "/admin", HelloWeb.Admin do
  pipe_through :browser

  resources "/reviews", ReviewController
end
```

新しいスコープを定義して、すべてのルートのプレフィックスが "/admin" で、すべてのコントローラーが `HelloWeb.Admin` 名前空間の下にあるようにします。

`mix phx.routes` を再度実行すると、以前のルートに加えて、次のような結果が得られます。

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

これは良さそうに見えますが、ここで問題があります。管理者向けの `/admin/reviews` と同様に、ユーザー向けのレビュールート `/reviews` も必要なのでした。このようにルートスコープの下にあるルーターにユーザー向けのレビューを含めると、次のようになります。

```elixir
scope "/", HelloWeb do
  pipe_through :browser

  ...
  resources "/reviews", ReviewController
end

scope "/admin", HelloWeb.Admin do
  pipe_through :browser

  resources "/reviews", ReviewController
end
```

そして `mix phx.routes` を実行すると、このような出力が得られます。

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

実際のルートは、各行の先頭にあるパスヘルパー `review_path` を除いて、すべて正しく見えます。ユーザーが利用するレビュールートと管理者が利用するレビュールートの両方で同じヘルパーを取得していますが、これは正しくありません。

この問題は、管理者スコープに `as: :admin` オプションを追加することで解決できます。

```elixir

scope "/admin", HelloWeb.Admin, as: :admin do
  pipe_through :browser

  resources "/reviews", ReviewController
end
```

これで `mix phx.routes` で欲しい結果が得られました。

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

パスヘルパーは、私たちが望むものを返すようになりました。`iex -S mix` を実行して、自分で試してみてください。

```elixir
iex(1)> HelloWeb.Router.Helpers.review_path(HelloWeb.Endpoint, :index)
"/reviews"

iex(2)> HelloWeb.Router.Helpers.admin_review_path(HelloWeb.Endpoint, :show, 1234)
"/admin/reviews/1234"
```

複数のリソースを管理者がすべて処理するとしたらどうでしょうか？このように、同じスコープ内にすべてのリソースを配置できます。

```elixir
scope "/admin", HelloWeb.Admin, as: :admin do
  pipe_through :browser

  resources "/images",  ImageController
  resources "/reviews", ReviewController
  resources "/users",   UserController
end
```

以下が `mix phx.routes` の結果です。

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

これは素晴らしいですね。まさに我々が欲しいものです。すべてのルート、パスヘルパー、コントローラーが適切な名前空間になっていることに注目してください。

スコープは任意に入れ子にすることもできますが、入れ子にするとコードが混乱してわかりにくくなることがあるので、慎重に行う必要があります。とはいえ、画像、レビュー、ユーザー用のリソースを定義したバージョニングされたAPIがあったとしましょう。その場合、技術的には以下のようにバージョニングされたAPIのルートを設定できます。

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

これらの定義がどのようになるかは `mix phx.routes` を実行することで確認できます。

興味深いことに、ルートが重複しないように注意していれば、同じパスで複数のスコープを使用できます。このルーターは、同じパスに2つのスコープが定義されていてもまったく問題ありません。

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

ルートを複製した場合、このおなじみの警告が表示されます。

```console
warning: this clause cannot match because a previous clause at line 16 always matches
```

## パイプライン

このガイドでは、ルーターで最初に見た行の1つである `pipe_through :browser` について語らずに、かなり長い道のりを歩んできました。それを語るときがきました。

パイプラインとは、特定のスコープに取り付けることができる一連のplugのことです。Plugに詳しくない方には、[詳細なガイド](plug.html)があります。

ルートはスコープ内で定義され、スコープは複数のパイプラインを通過できます。ルートが一致すると、Phoenixはそのルートに関連付けられたすべてのパイプラインで定義されたすべてのプラグを呼び出します。たとえば、"/" にアクセスすると `:browser` パイプラインを通過し、その結果、すべてのプラグが呼び出されます。

Phoenixはデフォルトで`:browser`と`:api`という2つのパイプラインを定義しており、多くの一般的なタスクに使用できます。これらのパイプラインをカスタマイズしたり、必要に応じて新しいパイプラインを作成したりできます。

### `:browser` と `:api` のパイプライン

名前が示すように、`:browser` パイプラインはブラウザへのリクエストをレンダリングするためのルートを準備します。`api` パイプラインはapiのデータを生成するルートの準備します。

`plug :accepts, ["html"]`はリクエストのフォーマットを定義し、`:fetch_session`はセッションデータを取得してコネクションで利用可能にするもので、`:fetch_flash`はセットされているフラッシュメッセージを取得するもので、`:protect_from_forgery`と`:put_secure_browser_headers`はクロスサイトフォージェリからフォーム投稿を保護するものです。

現在のところ、`:api` パイプラインは `plug :accepts, ["json"]` のみを定義しています。

ルーターは、スコープ内で定義されたルート上でパイプラインを呼び出します。スコープ外のルートにはパイプラインはありません。ネストされたスコープの使用はオススメしませんが (上記参照)、ネストされたスコープ内で `pipe_through` を呼び出すと、ルーターは親スコープからすべての `pipe_through` を呼び出し、その後にネストされたスコープを呼び出します。

たくさんの用語が束になっています。いくつかの例を見て、意味を紐解いてみましょう。

新しく生成されたPhoenixアプリケーションからルーターを見てみましょう。今回はapiスコープがコメントされておらず、ルートが追加されています。

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

サーバーがリクエストを受け入れるとき、リクエストは常に最初にEndpointのプラグを通過し、その後、パスとHTTP動詞にマッチしようとします。

リクエストが最初のルートである `/` へのGETにマッチしたとしましょう。ルーターはまずそのリクエストを `:browser` パイプラインにパイプし、セッションデータを取得してフラッシュを取得してフォージェリ保護を実行します。

逆に、リクエストが `resources/2` マクロで定義されたルートのいずれかにマッチした場合、ルーターは `:api` パイプライン (現在は何もしていない) を経由して `HelloWeb.ReviewController` の正しいアクションにディスパッチする前に、リクエストをパイプします。

ルートが一致しない場合、パイプラインは呼び出されず、404エラーが発生します。

これらの考えをもう少し広げてみましょう。リクエストを `:browser` と1つ以上のカスタムパイプラインの両方にパイプする必要があるとしたらどうでしょうか？パイプラインのリストを `pipe_through` するだけで、Phoenixはそれらのパイプラインを順番に呼び出します。

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

ここでは、異なるパイプラインを持つ2つのスコープの別の例を示します。

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

一般的に、パイプラインのスコーピングルールは期待通りの振る舞いをします。この例では、すべてのルートが `:browser` パイプラインを通過します。しかし、`reviews` リソースのルートだけが `:review_checks` パイプラインを通過します。`pipe_through [:browser, :review_checks]` と両方のパイプをパイプラインのリストで宣言しているので、Phoenixはそれぞれのパイプを順番に `pipe_through` します。

### 新しいパイプラインの作成

Phoenixでは、ルーター内の任意の場所に独自のカスタムパイプラインを作成できます。そのためには、`pipeline/2` マクロをこれらの引数で呼び出します。

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
    pipe_through [:browser, :review_checks]

    resources "/", ReviewController
  end
end
```

パイプライン自体はplugなので、パイプラインを別のパイプラインの中に組み込むことができます。たとえば、上の `review_checks` パイプラインを `browser` を自動的に呼び出すように書き換えることで、下流のパイプライン呼び出しを簡素化できます。

```elixir
  pipeline :review_checks do
    plug :browser
    plug :ensure_authenticated_user
    plug :ensure_user_owns_review
  end

  scope "/reviews", HelloWeb do
    pipe_through [:review_checks]

    resources "/", ReviewController
  end
```

## フォワード

`Phoenix.Router.forward/4` マクロを使用して、特定のパスで始まるすべてのリクエストを特定のplugへ送信できます。システムの一部がバックグラウンドでジョブを実行しているとします（別のアプリケーションやライブラリであっても構いません）。この管理者インターフェースに転送するには、次のようにします。

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

これは、`/jobs` で始まるすべてのルートが `HelloWeb.BackgroundJob.Plug` モジュールに送られることを意味します。プラグの中では、`/pending` や `/active` のように、特定のジョブのステータスを示すサブルートにマッチさせることができます。

パイプラインと `forward/4` マクロを混在させることもできます。ユーザーが認証済みで管理者であることを確認してジョブページを表示させたい場合は、ルーターで以下のようにすればよいでしょう。

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

これは、`authenticate_user` と `ensure_admin` パイプラインのプラグが `BackgroundJob.Plug` の前に呼び出され、適切なレスポンスを送信し、それに応じてリクエストを停止できることを意味します。

モジュールplugの `init/1` コールバックで受け取る `opts` は、第3引数として渡すことができます。たとえば、バックグラウンドジョブでページに表示するアプリケーションの名前を設定できます。と一緒に渡すことができます。

```elixir
forward "/jobs", BackgroundJob.Plug, name: "Hello Phoenix"
```

4番目の引数 `router_opts` を渡すことができます。これらのオプションの概要は `Phoenix.Router.scope/2` のドキュメントで説明されています。

`BackgroundJob.Plug`は、[Plugガイドで説明されている](plug.html)モジュールPlugとして実装できます。しかし、別のPhoenixエンドポイントに転送することはオススメしません。これは、あなたのアプリで定義されたplugと転送されたエンドポイントが2回呼び出され、エラーにつながる可能性があるからです。

## まとめ

ルーティングは大きなトピックであり、ここでは多くの分野をカバーしています。このガイドから取り上げる重要なポイントは以下の通りです。

- HTTP動詞名で始まるルートは、1つのmatch関数定義に展開されます。
- 'resources' で始まるルートは、8つのmatch関数定義に展開されます。
- リソースは、`only:` または `except:` オプションを使用してmatch関数の数を制限できます。
- これらのルートはいずれもネストさせることができます。
- これらのルートはいずれも指定したパスにスコープできます
- スコープで `as:` オプションを使うと重複を減らすことができます。
- スコープされたルートにヘルパーオプションを使用すると、到達不可能なパスを排除できます。
