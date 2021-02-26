---
layout: 1.5/layout
version: 1.5
group: testing
title: テストの導入
nav_order: 1
hash: 8a1d0826
---
# テストの導入

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

テストは、ソフトウェア開発プロセスに不可欠なものとなっており、意味のあるテストを簡単に書く能力は、現代のWebフレームワークにとって不可欠な機能です。Phoenixはこれに真剣に取り組んでおり、フレームワークのすべての主要なコンポーネントを簡単にテストできるようにするためのサポートファイルを提供しています。また、生成されたモジュールと一緒に、実世界の例を含むテストモジュールを生成して、私たちの作業を支援してくれます。

Elixirには[ExUnit](https://hexdocs.pm/ex_unit)と呼ばれるテストフレームワークが組み込まれています。ExUnitは簡潔で明快なテストを心がけており、魔法を最小限に抑えています。PhoenixはすべてのテストにExUnitを使用しています。ここでも使っていきます。

## テストの実行

PhoenixがWebアプリケーションを生成する際には、テストも含まれています。テストを実行するには、`mix test` と入力するだけです。

```console
$ mix test
....

Finished in 0.09 seconds
3 tests, 0 failures

Randomized with seed 652656
```

すでに3つのテストを実施しています!

実際には、テスト用のヘルパーやサポートファイルを含めて、すでにテスト用のディレクトリ構造が完全に設定されています。

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

無料で入手できるテストケースは `test/hello_web/controllers/page_controller_test.exs`, `test/hello_web/views/error_view_test.exs`, `test/hello_web/views/page_view_test.exs` です。これらはコントローラーとビューをテストしています。まだコントローラーとビューのガイドを読んでいないのであれば、今がチャンスです。

## テストモジュールを理解する

次のセクションでは、Phoenixのテスト構造に慣れるために使用します。まずは、Phoenixで生成された3つのテストファイルから始めます。

最初に見るテストファイルは `test/hello_web/controllers/page_controller_test.exs` です。

```elixir
defmodule HelloWeb.PageControllerTest do
  use HelloWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
```

ここではおもしろいことがいくつか起きています。

テストファイルは単純にモジュールを定義しています。各モジュールの先頭には、次のような行があります。

```elixir
use HelloWeb.ConnCase
```

Phoenixを利用しないElixirライブラリを書くとしたら、`use HelloWeb.ConnCase` の代わりに `use ExUnit.Case` を書くことになります。しかし、Phoenixにはコントローラーをテストするための多くの機能がすでに搭載されており、 `HelloWeb.ConnCase` は `ExUnit.Case` の上にビルドされているので、これらの機能を取り込むことができます。`HelloWeb.ConnCase` モジュールは後ほど解説します。

次に、`test/3` マクロを使って各テストを定義します。`test/3` マクロは3つの引数を受け取ります: テスト名、パターンマッチングを行うテストコンテキスト、テストの内容です。このテストでは、`get/2` マクロを使ってパス"/"への "GET" HTTPリクエストでアプリケーションのルートページにアクセスします。そして、レンダリングされたページに "Welcome to Phoenix!"という文字列が含まれていることを**アサート**します。

Elixirでテストを書くときには、アサーションを使って何かが真であることを確認します。この例では、`assert html_response(conn, 200) =~ "Welcome to Phoenix!` はいくつかのことをしています。

  * これは、`conn` がレスポンスをレンダリングしたことをアサートします
  * レスポンスのステータスコードが200であることをアサートします（HTTPの用語でOKを意味します）
  * レスポンスのタイプがHTMLであることをアサートします
  * HTMLレスポンスである `html_response(conn, 200)` の結果に "Welcome to Phoenix!" という文字列が含まれていることをアサートします

しかし、`get` や `html_response` で使う `conn` はどこから来ているのでしょうか？この疑問に答えるために、`HelloWeb.ConnCase` を見てみましょう。

## ConnCase

`test/support/conn_case.ex` を開くと、次のようなものがあります（コメントは削除されています）

```elixir
defmodule HelloWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      alias HelloWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint HelloWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Demo.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Demo.Repo, {:shared, self()})
    end

    %{conn: Phoenix.ConnTest.build_conn()}
  end
end
```

説明が必要なものがたくさんあります。

2行目には、これはケーステンプレートだと書かれています。これはExUnitの機能で、開発者は組み込みの `use ExUnit.Case` を自分のケースに置き換えることができます。この行のおかげで、コントローラーのテストの先頭に `use HelloWeb.ConnCase` を書くことができるようになりました。

さて、このモジュールをケーステンプレートにしたので、特定の場面で呼び出されるコールバックを定義してみましょう。`using` コールバックは、`use HelloWeb.ConnCase` を呼び出すすべてのモジュールに注入されるコードを定義します。この場合、コントローラーで利用できるコネクションヘルパーはすべてテストでも利用できるように、[`Plug.Conn`](https://hexdocs.pm/plug/Plug.Conn.html)をインポートしてから、[`Phoenix.ConnTest`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html)をインポートします。これらのモジュールを参照して、利用可能なすべての機能を学ぶことができます。

そして、すべてのパスヘルパーでモジュールをエイリアス化するので、テストで簡単にURLを生成できます。最後に、モジュールの `@endpoint` 属性にエンドポイントの名前を設定します。

そして、ケーステンプレートでは `setup` ブロックを定義します。この `setup` ブロックはテストの前に呼び出されます。セットアップブロックの大部分はSQLサンドボックスの設定に関するもので、これについては後ほど説明します。`setup` ブロックの最後の行には、次のような記述があります。

```elixir
%{conn: Phoenix.ConnTest.build_conn()}
```

`setup` の最後の行は、各テストで利用可能なテストのメタデータを返すことができます。ここで渡すメタデータは新しくビルドされた `Plug.Conn` です。このテストでは、テストの最初にこのメタデータからconnを抽出します。

```elixir
test "GET /", %{conn: conn} do
```

これがconnの由来です！最初のうちは、テスト構造には多少の間接性がありますが、この間接性はテストスイートの成長に伴って効果を発揮します。

## Viewのテスト

アプリケーション内の他のテストファイルは、ビューのテストを担当しています。

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

`HelloWeb.ErrorViewTest` は `async: true` を設定し、このテストケースが他のテストケースと並行して実行されることを意味します。ケース内の個々のテストは依然として連続的に実行されますが、これは全体のテスト速度を大幅に向上させることができます。

また、`render_to_string/3` 関数を使うために `Phoenix.View` をインポートしています。これで、すべてのアサーションは単純な文字列の等価テストになります。

ページビューケース `test/hello_web/views/page_view_test.exs` にはデフォルトではテストは含まれていませんが、`HelloWeb.PageView` モジュールに関数を追加する必要がある場合には、これを利用できます。

```elixir
defmodule HelloWeb.PageViewTest do
  use HelloWeb.ConnCase, async: true
end
```

## ディレクトリ/ファイルごとにテストを実行する

テストが何をしているかわかったので、それらを実行するためのさまざまな方法を見てみましょう。

このガイドの最初の方で見たように、`mix test` で一連のテスト全体を実行できます。

```console
$ mix test
....

Finished in 0.2 seconds
3 tests, 0 failures

Randomized with seed 540755
```

たとえば `test/hello_web/controllers` のように、指定したディレクトリですべてのテストを実行したい場合は、そのディレクトリへのパスを `mix test` に渡すことができます。

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

そして、ファイル名にコロンと行番号を追加することで、ファイル内の単一のテストを実行できます。

たとえば、`HelloWeb.ErrorView` が `500.html` をどのようにレンダリングするかだけのテストを実行したいとしましょう。テストはファイルの11行目から始まっているので、次のようにします。

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

## タグを利用したテストの実行

ExUnitでは、テストに個別に、あるいはモジュール全体にタグをつけることができます。特定のタグをつけたテストだけを実行することもできますし、 そのタグをつけたテストを除外してそれ以外のテストを実行することもできます。

これがどう動くのか実験してみましょう。

まず、`test/hello_web/views/error_view_test.exs` に `@moduletag` を追加します。

```elixir
defmodule HelloWeb.ErrorViewTest do
  use HelloWeb.ConnCase, async: true

  @moduletag :error_view_case
  ...
end
```

モジュールタグにアトムだけを指定した場合は、ExUnitはその値が `true` であるとみなします。別の値を指定することもできます。

```elixir
defmodule HelloWeb.ErrorViewTest do
  use HelloWeb.ConnCase, async: true

  @moduletag error_view_case: "some_interesting_value"
  ...
end
```

ここでは、単純なアトム `@moduletag :error_view_case` として残しておきましょう。

`mix test` に `--only error_view_case` を渡すことで、エラービューケースからのテストのみを実行できます。

```console
$ mix test --only error_view_case
Including tags: [:error_view_case]
Excluding tags: [:test]

...

Finished in 0.1 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 125659
```

> 注意: ExUnitは、テストの実行ごとにどのタグを含めたり除外したりしているのかを正確に教えてくれます。先ほどのテストの実行の節を見てみると、 個々のテストで指定した行番号が実際にはタグとして扱われていることがわかります。

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

しかし、`error_view_case` に `false` を指定しても、システム内に `error_view_case: false` にマッチするタグがないため、テストは実行されません。

```console
$ mix test --only error_view_case:false
Including tags: [error_view_case: "false"]
Excluding tags: [:test]



Finished in 0.1 seconds
3 tests, 0 failures, 3 excluded

Randomized with seed 622422
The --only option was given to "mix test" but no test executed
```

同様の方法で `--exclude` フラグを使うことができます。これはエラービューの場合を除いてすべてのテストを実行します。

```console
$ mix test --exclude error_view_case
Excluding tags: [:error_view_case]

.

Finished in 0.2 seconds
3 tests, 0 failures, 2 excluded

Randomized with seed 682868
```

タグに値を指定する方法は `--exclude` でも `--only` と同じです。

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

値に関係なく `individual_test` としてタグ付けされたテストのみを実行したい場合は、これが有効です。

```console
$ mix test --only individual_test
Including tags: [:individual_test]
Excluding tags: [:test]

..

Finished in 0.1 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 813729
```

また、値を指定して、その値でのみテストを実行することもできます。

```console
$ mix test --only individual_test:yup
Including tags: [individual_test: "yup"]
Excluding tags: [:test]

.

Finished in 0.1 seconds
3 tests, 0 failures, 2 excluded

Randomized with seed 770938
```

同様に、与えられた値でタグ付けされたもの以外のすべてのテストを実行できます。

```console
$ mix test --exclude individual_test:nope
Excluding tags: [individual_test: "nope"]

...

Finished in 0.2 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 539324
```

より具体的には、`individual_test` でタグ付けされた値が "yup" であるテストを除いて、すべてのテストをエラービューのケースから除外できます。

```console
$ mix test --exclude error_view_case --include individual_test:yup
Including tags: [individual_test: "yup"]
Excluding tags: [:error_view_case]

..

Finished in 0.2 seconds
3 tests, 0 failures, 1 excluded

Randomized with seed 61472
```

最後に、デフォルトでタグを除外するようにExUnitを設定します。デフォルトのExUnitの設定は `test/test_helper.exs` ファイルで行います。

```elixir
ExUnit.start(exclude: [error_view_case: true])

Ecto.Adapters.SQL.Sandbox.mode(Hello.Repo, :manual)
```

これで、`mix test` を実行すると、`page_controller_test.exs` から1つのspecだけが実行されるようになりました。

```console
$ mix test
Excluding tags: [error_view_case: true]

.

Finished in 0.2 seconds
3 tests, 0 failures, 2 excluded

Randomized with seed 186055
```

この動作を `--include` フラグでオーバーライドし、`mix test` に `error_view_case` でタグ付けされたテストを含めるように指示します。

```console
$ mix test --include error_view_case
Including tags: [:error_view_case]
Excluding tags: [error_view_case: true]

....

Finished in 0.2 seconds
3 tests, 0 failures

Randomized with seed 748424
```

このテクニックは、CIや特定のシナリオでしか実行したくないような、非常に長い時間実行されるテストを制御するのに非常に便利です。

## ランダム化

テストをランダムな順序で実行することは、テストが本当に分離されていることを保証する良い方法です。あるテストで散発的に失敗することに気がついた場合、それは前のテストでシステムの状態を変更したために、その後のテストに影響を与えてしまったからかもしれません。これらの失敗は、テストが特定の順序で実行された場合にのみ現れるかもしれません。

ExUnitはデフォルトで整数のシードを利用してテストの実行順をランダム化します。特定のランダムなシードが断続的な失敗の引き金になっていることに気づいた場合は、 同じシードでテストを再実行することで、そのテストの順番を確実に再現して問題の原因を突き止めることができます。

```console
$ mix test --seed 401472
....

Finished in 0.2 seconds
3 tests, 0 failures

Randomized with seed 401472
```

## 並列処理とパーティショニング

これまで見てきたように、ExUnitは開発者がテストを同時に実行できるようにします。これにより、開発者はマシンのパワーをすべて使ってテストスイートを可能な限り高速に実行できるようになります。これにPhoenixのパフォーマンスを組み合わせると、ほとんどのテストスイートは他のフレームワークと比べてほんのわずかな時間でコンパイルして実行できます。

通常、開発者は開発中に強力なマシンを使用できるようにしていますが、Continuous Integrationサーバーでは必ずしもそうとは限りません。そのため、ExUnitはテスト環境のテストパーティショニングもサポートしています。`config/test.exs` を開くと、データベース名の設定があります。

```elixir
database: "hello_test#{System.get_env("MIX_TEST_PARTITION")}",
```

デフォルトでは、環境変数 `MIX_TEST_PARTITION` は何も値を持ちません。しかし、CIサーバーでは、たとえば、4つの異なるコマンドを使うことで、テストスイートを複数のマシンに分割できます。

    MIX_TEST_PARTITION=1ミックステスト --パーティション4
    MIX_TEST_PARTITION=2ミックステスト --パーティション4
    MIX_TEST_PARTITION=3ミックステスト --パーティション4
    MIX_TEST_PARTITION=4ミックステスト --パーティション4

異なった名前のパーティションごとにデータベースを設定することを含めて、あとはExUnitとPhoenixが面倒を見てくれます。

## さらに深掘る

ExUnitはシンプルなテストフレームワークですが、`mix test` コマンドを使うことで非常に柔軟で堅牢なテストランナーを提供します。`mix help test` を実行したり、[オンラインのドキュメントを読む](https://hexdocs.pm/mix/Mix.Tasks.Test.html) ことをおすすめします。

新しく生成されたアプリを使って、Phoenixが何を提供してくれるかを見てきました。さらに、新しいリソースを生成するたびに、Phoenixはそのリソースに適したすべてのテストを生成します。たとえば、アプリケーションのルートで以下のコマンドを実行することで、スキーマ、コンテキスト、コントローラー、ビューを含む完全なスキャフォールドを作成できます。

```console
$ mix phx.gen.html Blog Post posts title body:text
* creating lib/demo_web/controllers/post_controller.ex
* creating lib/demo_web/templates/post/edit.html.eex
* creating lib/demo_web/templates/post/form.html.eex
* creating lib/demo_web/templates/post/index.html.eex
* creating lib/demo_web/templates/post/new.html.eex
* creating lib/demo_web/templates/post/show.html.eex
* creating lib/demo_web/views/post_view.ex
* creating test/demo_web/controllers/post_controller_test.exs
* creating lib/demo/blog/post.ex
* creating priv/repo/migrations/20200215122336_create_posts.exs
* creating lib/demo/blog.ex
* injecting lib/demo/blog.ex
* creating test/demo/blog_test.exs
* injecting test/demo/blog_test.exs

Add the resource to your browser scope in lib/demo_web/router.ex:

    resources "/posts", PostController


Remember to update your repository by running migrations:

    $ mix ecto.migrate

```

それでは、指示にしたがって `lib/hello_web/router.ex` ファイルに新しいリソースルートを追加し、マイグレーションを実行してみましょう。

再び `mix test` を実行すると、20個のテストがあることがわかります！

```console
$ mix test
................

Finished in 0.1 seconds
19 tests, 0 failures

Randomized with seed 537537
```

この時点で、我々はテストガイドの残りの部分に進むには絶好の場所にあり、その中で我々はこれらのテストをはるかに詳細に検討し、いくつかのテストを追加しましょう。
