---
layout: 1.5/layout
version: 1.5
group: testing
title: コントローラーのテスト
nav_order: 3
hash: 4ee3484f
---
# コントローラーのテスト

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: このガイドでは[テストの導入ガイド](testing.html)を前提としています

テスト入門ガイドの最後に、以下のコマンドを使って投稿用のHTMLリソースを生成しました。

```console
$ mix phx.gen.html Blog Post posts title body:text
```

これにより、PostControllerとそれに関連するテストを含む多くのモジュールが無料で提供されました。ここでは、一般的なコントローラーのテストについて学ぶために、これらのテストを探索していきます。ガイドの最後に、JSONリソースを生成し、APIテストがどのように見えるかを探っていきます。

## HTMLコントローラーのテスト

`test/hello_web/controllers/post_controller_test.exs` を開くと次のようになっています。

```elixir
defmodule HelloWeb.PostControllerTest do
  use HelloWeb.ConnCase

  alias Hello.Blog

  @create_attrs %{body: "some body", title: "some title"}
  @update_attrs %{body: "some updated body", title: "some updated title"}
  @invalid_attrs %{body: nil, title: nil}

  def fixture(:post) do
    {:ok, post} = Blog.create_post(@create_attrs)
    post
  end

  ...
```

アプリケーションに同梱されている `PageControllerTest` と同様に、このコントローラーテストでは `use HelloWeb.ConnCase` を使用してテスト構造を設定します。そして、いつものようにエイリアスを定義し、テスト中に使用するモジュールの属性を定義し、一連の `describe` ブロックを開始します。

### indexアクション

最初の記述ブロックは `index` アクションのためのものです。アクション自体は `lib/hello_web/controllers/post_controller.ex` のように実装されています。

```elixir
def index(conn, _params) do
  posts = Blog.list_posts()
  render(conn, "index.html", posts: posts)
end
```

すべての投稿を取得し、"index.html" テンプレートをレンダリングします。テンプレートは "lib/hello_web/templates/page/index.html.eex" にあります。

テストは次の通りです。

```elixir
describe "index" do
  test "lists all posts", %{conn: conn} do
    conn = get(conn, Routes.post_path(conn, :index))
    assert html_response(conn, 200) =~ "Listing Posts"
  end
end
```

`index` ページのテストは非常に簡単です。これは `Routes.post_path(conn, :index)` が返す "/posts" ページへのリクエストを行うために `get/2` ヘルパーを使います。

### createアクション

次に見るのは `create` アクションのテストである。`create` アクションの実装は次の通りです。

```elixir
def create(conn, %{"post" => post_params}) do
  case Blog.create_post(post_params) do
    {:ok, post} ->
      conn
      |> put_flash(:info, "Post created successfully.")
      |> redirect(to: Routes.post_path(conn, :show, post))

    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, "new.html", changeset: changeset)
  end
end
```

`create` には2つの結果が考えられるので、少なくとも2つのテストが必要です。

```elixir
describe "create post" do
  test "redirects to show when data is valid", %{conn: conn} do
    conn = post(conn, Routes.post_path(conn, :create), post: @create_attrs)

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == Routes.post_path(conn, :show, id)

    conn = get(conn, Routes.post_path(conn, :show, id))
    assert html_response(conn, 200) =~ "Show Post"
  end

  test "renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, Routes.post_path(conn, :create), post: @invalid_attrs)
    assert html_response(conn, 200) =~ "New Post"
  end
end
```

最初のテストは `post/2` リクエストから始まります。これは "/posts/new" ページのフォームがsubmitされると、createアクションへのPOSTリクエストになるからです。有効なattributeを渡したので、投稿は正常に作成され、新しい投稿のshowアクションにリダイレクトされているはずです。この新しいページは "/posts/ID" のようなアドレスを持つことになります。IDはデータベース内での投稿のidentifierです。

次に `redirected_params(conn)` を使って投稿のIDを取得し、実際にshowアクションにリダイレクトされたことを確認します。最後に、リダイレクト先のページへの `get` リクエストを行い、投稿が本当に作成されたかどうかを確認します。

2つめのテストでは、単純に失敗のシナリオをテストします。無効なattributeが与えられた場合、"New Post" ページを再レンダリングする必要があります。

よくある質問としては、コントローラーレベルでどれだけの失敗シナリオをテストしているのかということです。たとえば、[コンテキストのテスト](testing_contexts.html)ガイドでは、投稿の `title` フィールドにバリデーションを導入しています。

```elixir
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body])
  |> validate_required([:title, :body])
  |> validate_length(:title, min: 2)
end
```

つまり、投稿を作成すると以下のような理由で失敗することがあります。

  * titleがない
  * bodyがない
  * titleは存在するが、2文字未満

コントローラーのテストでは、これらの可能性のある結果をすべてテストする必要があるのでしょうか？

答えはノーです。異なるルールと結果のすべてを、コンテキストテストとスキーマテストで検証する必要があります。コントローラーは統合レイヤーとして機能します。コントローラーテストでは、成功と失敗の両方のシナリオを処理できるかどうかを大まかに検証したいだけです。

`update` のテストは `create` のテストと似たような構造をしているので、`delete` のテストに飛びます。

### deleteアクション

`delete` アクションは次のようになります。

```elixir
def delete(conn, %{"id" => id}) do
  post = Blog.get_post!(id)
  {:ok, _post} = Blog.delete_post(post)

  conn
  |> put_flash(:info, "Post deleted successfully.")
  |> redirect(to: Routes.post_path(conn, :index))
end
```

テストは次の通りです。

```elixir
  describe "delete post" do
    setup [:create_post]

    test "deletes chosen post", %{conn: conn, post: post} do
      conn = delete(conn, Routes.post_path(conn, :delete, post))
      assert redirected_to(conn) == Routes.post_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.post_path(conn, :show, post))
      end
    end
  end

  defp create_post(_) do
    post = fixture(:post)
    %{post: post}
  end
```

まず、`describe` ブロック内のすべてのテストの前に `create_post` 関数を実行することを `setup` で宣言します。`create_post` 関数は単に投稿を作成し、それをテストのメタデータに格納します。これにより、テストの最初の行でポストとコネクションの両方をマッチさせることができます。

```elixir
test "deletes chosen post", %{conn: conn, post: post} do
```

テストでは `delete/2` を使って投稿を削除し、indexページにリダイレクトしたことをアサートしています。最後に、削除された投稿のshowページにアクセスできなくなったことを確認します。

```elixir
assert_error_sent 404, fn ->
  get(conn, Routes.post_path(conn, :show, post))
end
```

`assert_error_sent` は `Phoenix.ConnTest` が提供するテストヘルパーです。この場合、次のことを検証します。

  1. 例外が発生したこと
  2. この例外は404（Not Foundの略）と同等のステータス・コードであること

これはPhoenixが例外を処理する方法をほぼ真似ています。たとえば、12345が存在しないIDである "/posts/12345" にアクセスした場合、`show` アクションを呼び出します。

```elixir
def show(conn, %{"id" => id}) do
  post = Blog.get_post!(id)
  render(conn, "show.html", post: post)
end
```

不明な投稿IDが `Blog.get_post!/1` に与えられると `Ecto.NotFoundError` が発生します。アプリケーションがウェブリクエスト中に例外を発生させた場合、Phoenixはそれらのリクエストを適切なHTTPレスポンスコードに変換します。この場合は404です。

たとえば、このテストを次のように書くことができました。

```elixir
assert_raise Ecto.NotFoundError, fn ->
  get(conn, Routes.post_path(conn, :show, post))
end
```

しかし、ブラウザが実際に受け取るであろうものを検証したいため、Phoenixがデフォルトで生成する実装の方が失敗の詳細を無視するため好ましいかもしれません。

`new`, `edit`, および `show` アクションのテストは、これまでに見てきたテストのよりシンプルなバリエーションです。アクションの実装とそれぞれのテストを自分でチェックできます。これでJSONコントローラーのテストに移る準備ができました。

## JSONコントローラーのテスト

これまでは、生成されたHTMLリソースを使って作業してきました。一方で、JSONリソースを生成したときのテストの様子を見てみましょう。

まず、このコマンドを実行します。

```console
$ mix phx.gen.json News Article articles title body
```

Blogコンテキスト <-> Postスキーマと非常に似た概念を選択していますが、これらの概念を分離して学習できるように別の名前を使用しています。

上記のコマンドを実行した後は、ジェネレーターが出力する最後のステップを忘れずに実行してください。すべてが完了したら、`mix test` を実行して、33のテストに合格するようにしましょう。

```console
$ mix test
................

Finished in 0.6 seconds
33 tests, 0 failures

Randomized with seed 618478
```

今回、スキャフォールドのコントローラーが生成するテストの数が減ったことにお気づきの方もいらっしゃるかもしれません。以前は16個のテストを生成していましたが（3個から19個）、今回は14個になりました（19個から33個）。これはJSON APIが `new` と `edit` アクションを公開する必要がないからです。これは `mix phx.gen.json` コマンドの最後にルーターに追加したリソースを見ればわかります。

```elixir
resources "/articles", ArticleController, except: [:new, :edit]
```

`new` と `edit` は基本的にユーザーがリソースを作成したり更新したりするのを支援するために存在するので、HTMLでは必要なだけです。アクションが少ないことに加えて、コントローラーやビューのテストやJSONの実装はHTMLのものとは大きく異なります。

HTMLとJSONの間でほとんど同じなのは、コンテキストとスキーマだけです。結局のところ、ビジネスロジックは、HTMLやJSONで公開しているかどうかにかかわらず、同じままであるべきです。

その違いを把握したうえで、コントローラーのテストを見てみましょう。

### indexアクション

`test/hello_web/controllers/article_controller_test.exs` を開きます。初期構造は `post_controller_test.exs` とよく似ています。それでは、`index` アクションのテストを見てみましょう。`index` アクション自体は `lib/hello_web/controllers/article_controller.ex` に次のように実装されています。

```elixir
def index(conn, _params) do
  articles = News.list_articles()
  render(conn, "index.json", articles: articles)
end
```

アクションはすべての記事を取得して "index.json" をレンダリングします。JSONについて話しているので、"index.json.eex" テンプレートはありません。代わりに、"article" をJSONに変換するコードはArticleViewモジュールで直接見つけることができ、`lib/hello_web/views/article_view.ex` で定義されています。

```elixir
defmodule HelloWeb.ArticleView do
  use HelloWeb, :view
  alias HelloWeb.ArticleView

  def render("index.json", %{articles: articles}) do
    %{data: render_many(articles, ArticleView, "article.json")}
  end

  def render("show.json", %{article: article}) do
    %{data: render_one(article, ArticleView, "article.json")}
  end

  def render("article.json", %{article: article}) do
    %{id: article.id,
      title: article.title,
      body: article.body}
  end
end
```

以前、`render_many` は[ビューとテンプレートガイド](views.html)で説明しました。今のところ知っておく必要があるのは、すべてのJSONリプライは "data" キーを持ち、その中に投稿のリスト（index用）か単一の投稿が含まれているということです。

それでは、`index` アクションのテストを見てみよう。

```elixir
describe "index" do
  test "lists all articles", %{conn: conn} do
    conn = get(conn, Routes.article_path(conn, :index))
    assert json_response(conn, 200)["data"] == []
  end
end
```

これは単に `index` パスにアクセスし、ステータス200のJSONレスポンスを取得し、返す記事がないので空のリストの "data" キーが含まれていることをアサートします。

これだと少し退屈ですね。もっとおもしろいものをみてみましょう。

### createアクション

`create` アクションはこのように定義されています。

```elixir
def create(conn, %{"article" => article_params}) do
  with {:ok, %Article{} = article} <- News.create_article(article_params) do
    conn
    |> put_status(:created)
    |> put_resp_header("location", Routes.article_path(conn, :show, article))
    |> render("show.json", article: article)
  end
end
```

見ての通り、記事が作成されたかどうかをチェックします。もしそうなら、ステータスコードを `:created`（201に変換されます）に設定し、記事の場所を含む "location" ヘッダーを設定し、記事を含む "show.json" をレンダリングします。

これはまさに `create` アクションの最初のテストで検証されていることです。

```elixir
describe "create" do
  test "renders article when data is valid", %{conn: conn} do
    conn = post(conn, Routes.article_path(conn, :create), article: @create_attrs)
    assert %{"id" => id} = json_response(conn, 201)["data"]

    conn = get(conn, Routes.article_path(conn, :show, id))

    assert %{
             "id" => id,
             "body" => "some body",
             "title" => "some title"
           } = json_response(conn, 200)["data"]
  end
```

テストでは `post/2` を使って新しい記事を作成し、記事がステータス201のJSONレスポンスを返し、その中に "data" キーが含まれていることを確認します。"data" を `%{"id" => id}` でパターンマッチし、これにより、新しい記事のIDを抽出できます。次に、`show` ルート上で `get/2` リクエストを実行し、記事が正常に作成されたことを確認します。

`describe "create"` の中には、失敗のシナリオを扱う別のテストがあります。`create` アクションの中にある失敗シナリオを見つけることができますか？振り返ってみましょう。

```elixir
def create(conn, %{"article" => article_params}) do
  with {:ok, %Article{} = article} <- News.create_article(article_params) do
```

Elixirの一部として提供されている `with` を使うと、ハッピーパスを明示的にチェックできます。この場合、私たちは `News.create_article(article_params)` が `{:ok, article}` を返すシナリオにのみ興味があります。もしそれが他の何かを返すならば、他の値は単に直接返され、`do/end` ブロック内のコンテンツは何も実行されません。つまり、`News.create_article/1` が `{:error, changeset}` を返した場合は、単に `{:error, changeset}` をアクションから返すことになります。

しかし、これには問題があります。アクションはデフォルトで `{:error, changeset}` の結果を処理する方法を知りません。幸いなことに、Phoenix Controllersにアクションフォールバックコントローラーで処理する方法を教えることができます。`ArticleController` の冒頭には以下のようなものがあります。

```elixir
  action_fallback HelloWeb.FallbackController
```

この行は、`%Plug.Conn{}` が返ってこない場合は、その結果を使って `FallbackController` を呼び出すという意味です。`HelloWeb.FallbackController` は `lib/hello_web/controllers/fallback_controller.ex` にあり、次のようになっています。

```elixir
defmodule HelloWeb.FallbackController do
  use HelloWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(HelloWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(HelloWeb.ErrorView)
    |> render(:"404")
  end
end
```

`call/2` 関数の最初の節が `{:error, changeset}` の場合をどのように処理し、ステータスコードを処理不可能なエンティティ（422）に設定し、失敗したチェンジセットでチェンジセットビューから "error.json" をレンダリングするかを見ることができます。

このことを念頭に置いて、`create` の2回目のテストを見てみよう。

```elixir
test "renders errors when data is invalid", %{conn: conn} do
  conn = post(conn, Routes.article_path(conn, :create), article: @invalid_attrs)
  assert json_response(conn, 422)["errors"] != %{}
end
```

これは単に無効なパラメーターを指定して `create` パスにpostするだけです。これにより、ステータスコード422のJSONレスポンスと、空ではない "errors" キーを持つレスポンスを返すようになります。

`action_fallback` は、APIを設計する際にボイラプレートを減らすのに非常に便利です。アクションフォールバックについては、[コントローラーガイド](controllers.html)を参照してください。

### deleteアクション

最後に、最後のアクションはJSONのための `delete` アクションです。その実装は次のようになります。

```elixir
def delete(conn, %{"id" => id}) do
  article = News.get_article!(id)

  with {:ok, %Article{}} <- News.delete_article(article) do
    send_resp(conn, :no_content, "")
  end
end
```

新しいアクションは単に記事の削除を試み、成功した場合、ステータスコード `:no_content`（204）を持つ空のレスポンスを返します。

テストは次の通りです。

```elixir
describe "delete article" do
  setup [:create_article]

  test "deletes chosen article", %{conn: conn, article: article} do
    conn = delete(conn, Routes.article_path(conn, :delete, article))
    assert response(conn, 204)

    assert_error_sent 404, fn ->
      get(conn, Routes.article_path(conn, :show, article))
    end
  end
end

defp create_article(_) do
  article = fixture(:article)
  %{article: article}
end
```

これは新しい記事をセットアップし、テストでは `delete` パスを呼び出してそれを削除し、204のレスポンスでJSONでもHTMLでもないことをアサートします。そして、その記事にアクセスできなくなったことを確認します。

以上です！

これで、HTMLとJSON APIの両方でスキャフォールドのコードとそのテストがどのように機能するかを理解したので、Webアプリケーションの構築と保守を進める準備が整いました。
