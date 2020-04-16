---
layout: default
group: testing
title: テストの紹介
nav_order: 1
hash: 5d132fdb587634ec2322586785b1408886481beb
---
# テストの紹介

> 注：テストガイドはPhoenix 1.3には完全に更新されていません。作業中であり、より多くのコンテンツが増えるでしょう。

テストは、ソフトウェア開発プロセスに不可欠なものとなっており、意味のあるテストを簡単に書く能力は、現代のWebフレームワークにとって不可欠な機能です。Phoenixはこれに真剣に取り組んでおり、フレームワークのすべての主要なコンポーネントを簡単にテストできるようにするためのサポートファイルを提供しています。また、生成されたモジュールと一緒に、実世界の例を含むテストモジュールを生成して、私たちの作業を支援してくれます。

Elixir には [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) と呼ばれるテストフレームワークが組み込まれています。ExUnit は簡潔で明快なテストを心がけており、魔法を最小限に抑えています。Phoenix はすべてのテストに ExUnit を使用しています。ここでも使っていきます。

ExUnitはテストモジュールのことを「テストケース」と呼んでいますが、これと同じことをします。

これを実際に見てみましょう。

> 注意: 先に進む前に、システムにPostgreSQLをインストールして実行しておく必要があります。また、正しいログイン認証情報でレポを設定する必要があります。[Mixタスクガイド内のecto.create節](../phoenix_mix_tasks.html#ecto-specific-mix-tasks)には多くの情報があります。また、[Ectoガイド](../ecto.html)には、それがどのように動作するかについての詳細が書かれています。

新しく生成したアプリケーション(例では "hello "という名前のプロジェクトを使っています)では、プロジェクトのルートで `mix test` を実行してみましょう。(新規アプリケーションの生成方法については、[起動](../up_and_running.html)を参照してください)。

```console
$ mix test
....

Finished in 0.09 seconds
3 tests, 0 failures

Randomized with seed 652656
```

もうすでに3件のテストがあります!

実際には、テスト用のヘルパーやサポートファイルなどのディレクトリ構造はすでに完全に設定されています。

> 注: テストヘルパーがすべてのことをやってくれたので、テストデータベースを作成したり、マイグレートしたりする必要はありませんでした。

```console
test
├── hello_web
│   ├── channels
│   ├── controllers
│   │   └── page_controller_test.exs
│   └── views
│       ├── error_view_test.exs
│       ├── layout_view_test.exs
│       └── page_view_test.exs
├── support
│   ├── channel_case.ex
│   ├── conn_case.ex
│   └── data_case.ex
└── test_helper.exs
```

はじめから用意されているテストケースは、`test/hello_web/controllers/page_controller_test.exs`、`test/hello_web/views/error_view_test.exs`、`test/hello_web/views/page_view_test.exs`です。素敵ですね。

テストガイドではテストケースの詳細を見ていきますが、まずはこの3つのテストケースを手始めに見てみましょう。

最初に見てみるテストケースは `test/hello_web/controllers/page_controller_test.exs` です。

```elixir
defmodule HelloWeb.PageControllerTest do
  use HelloWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
```

ここでは面白いことがいくつか起きています。

関数 `get/2` は、あたかも "/" へのGETリクエストに使用されたかのようにコネクション構造体をセットアップしてくれます。これにより、かなりの量の面倒な設定を省くことができます。

アサーションは、実際に 3 つのことをテストしています - HTML レスポンスを受け取ったこと (content-type が "text/html"であること)、レスポンスコードが 200 であること、レスポンスのbodyに文字列 "Welcome to Phoenix!" が含まれていること。

エラービューのテストケース `test/hello_web/views/error_view_test.exs` は、それ自体がいくつかの興味深いことを示しています。

```elixir
defmodule HelloWeb.ErrorViewTest do
  use HelloWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(HelloWeb.ErrorView, "404.html", []) ==
           "Not Found"
  end

  test "renders 500.html" do
    assert render_to_string(HelloWeb.ErrorView, "500.html", []) ==
           "Internal Server Error"
  end
end
```

`HelloWeb.ErrorViewTest` は `async: true` を設定し、このテストケースが他のテストケースと並行して実行されることを意味します。ケース内の個々のテストはまだ連続的に実行されますが、これは全体的なテスト速度を大幅に向上させることができます。非同期テストでは奇妙な動作に遭遇する可能性がありますが、[`Ecto.Adapters.SQL.Sandbox`](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html) のおかげで、データベースを含む非同期テストは安心して行うことができます。これは、Phoenixアプリケーションのテストの大部分が非同期で実行できることを意味します。

また、`render_to_string/3` 関数を使うために `Phoenix.View` をインポートしています。これで、すべてのアサーションは単純に文字列が一致するかどうかのテストにすることができます。

ページビューのケース `test/hello_web/views/page_view_test.exs` にはデフォルトではテストは含まれていませんが、`HelloWeb.PageView` モジュールに関数を追加する必要がある場合には、これを利用することができます。

```elixir
defmodule HelloWeb.PageViewTest do
  use HelloWeb.ConnCase, async: true
end
```

Phoenixが提供してくれるサポートファイルとヘルパーファイルも見てみましょう。

デフォルトのテストヘルパーファイル `test/test_helper.exs` は、テストデータベースを作成してマイグレートします。また、各テストを実行するためのトランザクションを開始します。これは、各テストが完了するたびにトランザクションをロールバックすることでデータベースを "初期化" しています。

テストヘルパーは、アプリケーションが必要とするテスト固有の設定を保持することもできます。

```elixir
ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Hello.Repo, :manual)
```

`test/support` にあるファイルは、モジュールをテスト可能な状態にするための手助けをしてくれます。これらのファイルは、コネクション構造体を設定したり、Ecto チェンジセットでエラーを見つけたりするための便利な機能を提供します。残りのテストガイドでは、これらのファイルの動作を詳しく見ていきます。

### テスト実行

テストが何をしているかわかったので、それらを実行するためのさまざまな方法を見てみましょう。

このガイドの最初の方で見たように、`mix test`で一連のテスト全体を実行することができます。

```console
$ mix test
....

Finished in 0.2 seconds
3 tests, 0 failures

Randomized with seed 540755
```

例えば `test/hello_web/controllers` のように、指定したディレクトリですべてのテストを実行したい場合は、そのディレクトリへのパスを `mix test` に渡すことができます。

```console
$ mix test test/hello_web/controllers/
.

Finished in 0.2 seconds
1 tests, 0 failures

Randomized with seed 652376
```

特定のファイル内のすべてのテストを実行するためには、そのファイルのパスを `mix test` に渡すことができます。

```console
$ mix test test/hello_web/views/error_view_test.exs
...

Finished in 0.2 seconds
2 tests, 0 failures

Randomized with seed 220535
```

そして、ファイル名にコロンと行番号を追加することで、ファイル内の単一のテストを実行することができます。

例えば、`HelloWeb.ErrorView` が `500.html` をどのようにレンダリングするかだけのテストを実行したいとしましょう。テストはファイルの12行目から始まっているので、以下のようにします。

```console
$ mix test test/hello_web/views/error_view_test.exs:11
Including tags: [line: "11"]
Excluding tags: [:test]

.

Finished in 0.1 seconds
2 tests, 0 failures, 1 excluded

Randomized with seed 288117
```

ここではテストの最初の行を指定して実行することにしましたが、実際にはテストのどの行でも実行できます。これらの行番号はすべて動作します - `:11`, `:12`, `:13` です。

### タグを使ったテストの実行

ExUnit では、ケースレベルや個別のテストレベルでテストにタグをつけることができます。特定のタグをつけたテストだけを実行したり、そのタグをつけたテストを除外してそれ以外のテストを実行したりすることができます。

これがどう動くのか実験してみましょう。

まず、`test/hello_web/views/error_view_test.exs`に `@moduletag` を追加します。

```elixir
defmodule HelloWeb.ErrorViewTest do
  use HelloWeb.ConnCase, async: true

  @moduletag :error_view_case
  ...
end
```

モジュールタグにアトムだけを指定した場合は、ExUnit はその値が `true` であるとみなします。お望みであれば、別の値を指定することもできます。

```elixir
defmodule HelloWeb.ErrorViewTest do
  use HelloWeb.ConnCase, async: true

  @moduletag error_view_case: "some_interesting_value"
  ...
end
```

とりあえず、単純なアトム `@moduletag :error_view_case` として残しておきましょう。

`mix test` に `--only error_view_case` を渡すことで、エラービューケースからのテストのみを実行することができます。

```console
$ mix test --only error_view_case
Including tags: [:error_view_case]
Excluding tags: [:test]

...

Finished in 0.1 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 125659
```

> 注記: ExUnit は、テストの実行ごとにどのタグを含めたり除外したりしているのかを正確に教えてくれます。前節のテストの実行についての説明を見てみると、 個々のテストで指定した行番号が実際にはタグとして扱われていることがわかります。

```console
$ mix test test/hello_web/views/error_view_test.exs:11
Including tags: [line: "11"]
Excluding tags: [:test]

.

Finished in 0.2 seconds
2 tests, 0 failures, 1 excluded

Randomized with seed 364723
```

`error_view_case` に `true` を指定しても同じ結果が得られます。

```console
$ mix test --only error_view_case:true
Including tags: [error_view_case: "true"]
Excluding tags: [:test]

...

Finished in 0.1 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 833356
```

しかし、`error_view_case` に `false` を指定してもテストは実行されません。それは `error_view_case: false` にマッチするタグが私達のシステムの中にはないからです。

```console
$ mix test --only error_view_case:false
Including tags: [error_view_case: "false"]
Excluding tags: [:test]



Finished in 0.1 seconds
3 tests, 0 failures, 3 excluded

Randomized with seed 622422
The --only option was given to "mix test" but no test executed
```

同様の方法で `--exclude` フラグを使うことができます。これはエラービューのケースを除いてすべてのテストを実行します。

```console
$ mix test --exclude error_view_case
Excluding tags: [:error_view_case]

.

Finished in 0.2 seconds
3 tests, 0 failures, 2 excluded

Randomized with seed 682868
```

タグに値を指定する方法は `--exclude` でも `--only` と同じ方法で動作します。

完全なテストケースだけでなく、個々のテストにもタグを付けることができます。これがどのように動作するのか、エラービューのケースにいくつかのテストをタグ付けしてみましょう。

```elixir
defmodule HelloWeb.ErrorViewTest do
  use HelloWeb.ConnCase, async: true

  @moduletag :error_view_case

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  @tag individual_test: "yup"
  test "renders 404.html" do
    assert render_to_string(HelloWeb.ErrorView, "404.html", []) ==
           "Not Found"
  end

  @tag individual_test: "nope"
  test "renders 500.html" do
    assert render_to_string(HelloWeb.ErrorView, "500.html", []) ==
           "Internal Server Error"
  end
end
```

値に関係なく `individual_test` としてタグ付けされたテストのみを実行したい場合は、以下のようにすれば実行できます。

```console
$ mix test --only individual_test
Including tags: [:individual_test]
Excluding tags: [:test]

..

Finished in 0.1 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 813729
```

また、値を指定して、その値をもったテストのみを実行することもできます。

```console
$ mix test --only individual_test:yup
Including tags: [individual_test: "yup"]
Excluding tags: [:test]

.

Finished in 0.1 seconds
3 tests, 0 failures, 2 excluded

Randomized with seed 770938
```

同様に、与えられた値でタグ付けされたもの以外のすべてのテストを実行することができます。

```console
$ mix test --exclude individual_test:nope
Excluding tags: [individual_test: "nope"]

...

Finished in 0.2 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 539324
```

もっと指定を増やして、`individual_test` でタグ付けされた値が "yup" であるテストを除いて、エラービューのケースからすべてのテストを除外することができます。

```console
$ mix test --exclude error_view_case --include individual_test:yup
Including tags: [individual_test: "yup"]
Excluding tags: [:error_view_case]

..

Finished in 0.2 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 61472
```

最後に、タグを除外するように ExUnit をデフォルトで設定することができます。`test/test_helper.exs` に `error_view_case` タグを持つテストを常に除外するように設定してみましょう。

```elixir
ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Hello.Repo, :manual)

ExUnit.configure(exclude: [error_view_case: true])
```

これで、`mix test`を実行すると、`page_controller_test.exs`から1つのスペックだけが実行されるようになりました。

```console
$ mix test
Excluding tags: [error_view_case: true]

.

Finished in 0.2 seconds
3 tests, 0 failures, 2 excluded

Randomized with seed 186055
```

この動作を `--include` フラグでオーバーライドし、`mix test` に `error_view_case` でタグ付けされたテストを含めるように指示することができます。

```console
$ mix test --include error_view_case
Including tags: [:error_view_case]
Excluding tags: [error_view_case: true]

....

Finished in 0.2 seconds
3 tests, 0 failures

Randomized with seed 748424
```

### ランダム化

テストをランダムな順序で実行することは、テストが本当に分離されていることを保証する良い方法です。あるテストで散発的に失敗することに気がついた場合、それは前のテストでシステムの状態を変更し後始末がされず、その後のテストに影響を与えてしまったからかもしれません。これらの失敗は、テストが特定の順序で実行された場合にのみ現れるかもしれません。

ExUnit はデフォルトでテストの実行順をランダムな整数を使ってランダム化します。特定のランダムなシードが断続的な失敗の引き金になっていることに気づいた場合は、 同じシードでテストを再実行することで、そのテストの順番を確実に再現して問題の原因を突き止めることができます。

```console
$ mix test --seed 401472
....

Finished in 0.2 seconds
3 tests, 0 failures

Randomized with seed 401472
```

### 生成ファイル

新しく生成されたアプリで、Phoenixが何を提供してくれるかを見てきました。では、新しい HTML リソースを生成するとどうなるか見てみましょう。

[Ectoガイド](../ecto.html)で作成した`users`リソースを拝借してみましょう。

新しいアプリケーションのルートで、`mix phx.gen.html` タスクを以下のオプションで実行してみましょう。

```console
$ mix phx.gen.html Users User users name:string email:string bio:string number_of_pets:integer

* creating lib/hello_web/controllers/user_controller.ex
* creating lib/hello_web/templates/user/edit.html.eex
* creating lib/hello_web/templates/user/form.html.eex
* creating lib/hello_web/templates/user/index.html.eex
* creating lib/hello_web/templates/user/new.html.eex
* creating lib/hello_web/templates/user/show.html.eex
* creating lib/hello_web/views/user_view.ex
* creating test/hello_web/controllers/user_controller_test.exs
* creating lib/hello/users/user.ex
* creating priv/repo/migrations/20180904210841_create_users.exs
* creating lib/hello/users.ex
* injecting lib/hello/users.ex
* creating test/hello/users/users_test.exs
* injecting test/hello/users/users_test.exs

Add the resource to your browser scope in lib/hello_web/router.ex:

    resources "/users", UserController

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

それでは、指示に従って `lib/hello_web/router.ex` ファイルに新しいリソースルートを追加してみましょう。

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  ...

  scope "/", Hello do
    pipe_through :browser

    get "/", PageController, :index
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Hello do
  #   pipe_through :api
  # end
end
```

もう一度 `mix test` を実行してみると、すでに19件のテストが行われていることがわかります！

```console
$ mix test
................

Finished in 0.1 seconds
19 tests, 0 failures

Randomized with seed 537537
```

この時点で、我々はテストガイドの残りの部分に移行するには絶好の場所にあり、その中で我々はこれらのテストをはるかに詳細に検討し、さらに追加をしていきます。
