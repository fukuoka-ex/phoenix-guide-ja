---
layout: 1.5/layout
version: 1.5
group: testing
title: コンテキストのテスト
nav_order: 2
hash: 4ee3484f
---
# コンテキストのテスト

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: [テストの導入ガイド](testing.html)を理解していることを前提としています

> **前提**: このガイドでは、[コンテキストガイド](contexts.html)の内容を前提としています

テスト入門ガイドの最後に、以下のコマンドを使って投稿用のHTMLリソースを生成しました。

```console
$ mix phx.gen.html Blog Post posts title body:text
```

これにより、BlogコンテキストとPostスキーマを含む多くのモジュールを、それぞれのテストファイルと一緒に無料で提供してくれました。コンテキストガイドで学んだように、Blogコンテキストはビジネスドメインの特定の領域に対応する機能を持つモジュールで、ポストスキーマはデータベースの特定のテーブルにマップします。

このガイドでは、コンテキストとスキーマのために生成されたテストについて調べていきます。他のことをする前に、`mix test` を実行してテストスイートがきれいに動作することを確認しましょう。

```console
$ mix test
................

Finished in 0.6 seconds
19 tests, 0 failures

Randomized with seed 638414
```

いいですね。19のテストがありますが、すべて合格しています!

## postsをテストする

`test/hello/blog_test.exs` を開くと、以下のようなファイルが出てきます。

```elixir
defmodule Hello.BlogTest do
  use Hello.DataCase

  alias Hello.Blog

  describe "posts" do
    alias Hello.Blog.Post

    @valid_attrs %{body: "some body", title: "some title"}
    @update_attrs %{body: "some updated body", title: "some updated title"}
    @invalid_attrs %{body: nil, title: nil}

    def post_fixture(attrs \\ %{}) do
      {:ok, post} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Blog.create_post()

      post
    end

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Blog.list_posts() == [post]
    end

    ...
```

ファイルの先頭には `Hello.DataCase` をインポートしています。`HelloWeb.ConnCase` がコネクションを扱うためのヘルパーを設定するのに対し、`Hello.DataCase` はコンテキストやスキーマを扱うための機能を提供します。

次にエイリアスを定義して、`Hello.Blog` を単に `Blog` として参照できるようにします。

そして、`describe "posts"` ブロックを開始します。`describe` ブロックはExUnitの機能で、似たようなテストをグループ化できます。ここで投稿に関連するテストをまとめているのは、Phoenixのコンテキストでは複数のスキーマをまとめてグループ化することができるからです。たとえば、次のようなコマンドを実行したとします。

```console
$ mix phx.gen.html Blog Comment comments post_id:references:posts body:text
```

`Hello.Blog` のコンテキストに新しい関数をたくさん追加し、テストファイルに新しい `describe "comments"` ブロックを追加する予定です。

コンテキストのために定義されたテストは非常にわかりやすいものです。これらのテストはコンテキスト内の関数を呼び出し、その結果をアサートします。ご覧のように、これらのテストの中にはデータベースにエントリを作成するものもあります。

```elixir
test "create_post/1 with valid data creates a post" do
  assert {:ok, %Post{} = post} = Blog.create_post(@valid_attrs)
  assert post.body == "some body"
  assert post.title == "some title"
end
```

この時点であるテストで作成されたデータが他のテストに影響を与えないようにするにはどうすればよいのか？と疑問に思うかもしれません。この質問に答えるために、`DataCase` について説明しましょう。

## DataCase

`test/support/data_case.ex` を開くと以下のようになっています。

```elixir
defmodule Hello.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Hello.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Hello.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Hello.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Hello.Repo, {:shared, self()})
    end

    :ok
  end

  def errors_on(changeset) do
    ...
  end
end
```

`Hello.DataCase` は別の `ExUnit.CaseTemplate` です。`using` ブロックでは、`DataCase` がテストに持ち込むエイリアスやインポートのすべてを見ることができます。`DataCase` の `setup` チャンクは `ConnCase` のものとよく似ています。見ての通り、`setup` ブロックの大部分はSQLサンドボックスの設定を中心にしています。

SQLサンドボックスはまさに、他のテストに影響を与えることなく、テストがデータベースに書き込むことを可能にするものです。一言で言えば、すべてのテストの最初に、データベース内のトランザクションを開始します。テストが終了すると、自動的にトランザクションをロールバックし、テストで作成されたデータを効果的にすべて消去します。

さらに、SQLサンドボックスでは、複数のテストがデータベースと通信している場合でも、複数のテストを同時に実行できます。この機能はPostgreSQLデータベース用に提供されており、それらを使用する際に `async: true` フラグを追加することで、コンテキストやコントローラーのテストをさらに高速化するために使用できます。

```elixir
use Hello.DataCase, async: true
```

サンドボックスで非同期テストを実行する際には、いくつかの考慮すべき点がありますので、詳細は [`Ecto.Adapters.SQL.Sandbox`](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html) を参照してください。

最後に `DataCase` モジュールの最後に `errors_on` という名前の関数があります。この関数はスキーマに追加したい検証をテストするために使われます。独自のバリデーションを追加してテストしてみましょう。

## スキーマのテスト

HTML Postリソースを生成すると、PhoenixはBlogコンテキストとPostスキーマを生成しました。コンテキスト用のテストファイルは生成されましたが、スキーマ用のテストファイルは生成されませんでした。しかし、これはスキーマをテストする必要がないという意味ではなく、これまでのところスキーマをテストする必要がなかったということです。

では、いつコンテキストを直接テストするのか、いつスキーマを直接テストするのか、疑問に思うかもしれません。この質問に対する答えは、いつコンテキストにコードを追加し、いつスキーマにコードを追加するかという質問に対する答えと同じです。

一般的なガイドラインは、副作用のないコードはすべてスキーマに入れておくことです。言い換えれば、単にデータ構造やスキーマ、チェンジセットを扱うだけならば、スキーマの中に入れておきましょう。コンテキストでは、スキーマを作成したり更新したりしてデータベースやAPIに書き込むコードが一般的でしょう。

スキーマモジュールにバリデーションを追加する予定なので、スキーマに特化したテストを書く絶好の機会です。`lib/hello/blog/post.ex` を開き、以下のバリデーションを `def changeset` に追加します。

```elixir
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body])
  |> validate_required([:title, :body])
  |> validate_length(:title, min: 2)
end
```

新しいバリデーションでは、タイトルには最低2文字以上の文字数が必要となっています。このためのテストを書いてみましょう。`test/hello/blog/post_test.exs` に新しいファイルを作成します。

```elixir
defmodule Hello.Blog.PostTest do
  use Hello.DataCase, async: true
  alias Hello.Blog.Post

  test "title must be at least two characters long" do
    changeset = Post.changeset(%User{}, %{title: "I"})
    assert %{title: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end
end
```

これで終わりです。ビジネスドメインが成長するにつれ、コンテキストとスキーマをテストするための場所が明確に定義されています。
