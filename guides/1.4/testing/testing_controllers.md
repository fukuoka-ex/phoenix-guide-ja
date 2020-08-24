---
layout: 1.4/layout
version: 1.4
group: testing
title: コントローラーのテスト
nav_order: 3
hash: 5d132fdb587634ec2322586785b1408886481beb
---
# コントローラーのテスト

JSON api 用のエンドポイントを持つコントローラーをテスト駆動で開発する方法をみて行きましょう。

Phoenixには、以下のようなJSONリソースを作成するためのジェネレータがあります:

```console
$ mix phx.gen.json  AllTheThings Thing things some_attr:string another_attr:string
```

このコマンドにおいて、AllTheThingsはコンテキストです。Thingはスキーマです。thingsはスキーマの複数形の名前です。(そしてthingsはテーブル名として使われます)。`some_attr`と`another_attr`は`things`テーブルのデータベースカラムであり、型は文字列型です。

しかしながら、実際にはこのコマンドは実行*しないでください*。そのかわりに、ジェネレーターが自動的に作ってくれるものと同じような結果が得られるかどうかテスト駆動で詳しくみてみることにしましょう。

### 準備

もしまだ以下のようにphx.newをしていないなら、以下のコマンドを実行することで空のプロジェクトを最初に作っておきましょう。

```console
$ mix phx.new hello
```

新しくつくられた`hello`ディレクトリに移動して、`config/dev.exs`でデータベースの設定を行ってから以下を実行してください。

```console
$ mix ecto.create
```

もしこの手順について疑問があれば、[起動ガイド](../up_and_running.html)へジャンプすることをいつやるの？　今でしょ。

この例では`Accounts`コンテキストを作ってみましょう。コンテキスト作成はこのガイドのスコープの範疇を超えるため、ここではジェネレーターを使うことにします。もしコンテキストの詳細を知りたければ、[Mixタスク](../phoenix_mix_tasks.html#独自のmixタスクを作成する)や[コンテキスト](../contexts.html#content)を確認してみましょう。

```console
$ mix phx.gen.context Accounts User users name:string email:string:unique password:string

* creating lib/hello/accounts/user.ex
* creating priv/repo/migrations/20170913155721_create_users.exs
* creating lib/hello/accounts.ex
* injecting lib/hello/accounts.ex
* creating test/hello/accounts/accounts_test.exs
* injecting test/hello/accounts/accounts_test.exs

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

通常、生成されたマイグレーションファイル(`priv/repo/migrations/<datetime>_create_users.exs`)にNOT NULL制約などを追加するために微調整に時間を費やしますが、今回は何も変更は加えず、ただマイグレーションを実行します。

```console
$ mix ecto.migrate
Compiling 2 files (.ex)
Generated hello app
[info] == Running Hello.Repo.Migrations.CreateUsers.change/0 forward
[info] create table users
[info] create index users_email_index
[info] == Migrated in 0.0s
```

開発を開始するまえの最終チェックとして、`mix test`を実行して、すべてのテストがパスしていることを確かめておきましょう。

```console
$ mix test
```

すべてのテストはパスするはずですが、まれにデータベースの設定が`config/test.exs`で適切にされていなかったり、別の問題が発生する場合があります。意図的にテストを壊して物事を複雑にする*前に*、今すぐこれらの問題を修正するのがベストです!

### テスト駆動開発

これからやっていく題材は、標準的なCRUDアクションをもったコントローラーです。テスト駆動開発でやっていくのでテストの作成から始めます。`test/hello_web/controllers`内に`user_controller_test.exs`を作りましょう。

```elixir
defmodule HelloWeb.UserControllerTest do
  use HelloWeb.ConnCase

end
```

テスト駆動開発の進め方には様々な方法があります。ここでは、実行したいアクションを一つ一つ考え、期待通りに物事が進む「ハッピーパス」と、何かがうまくいかない場合の「エラーケース」（該当する場合）を扱っていきます。

```elixir
defmodule HelloWeb.UserControllerTest do
  use HelloWeb.ConnCase

  test "index/2 responds with all Users"

  describe "create/2" do
    test "Creates, and responds with a newly created user if attributes are valid"
    test "Returns an error and does not create a user if attributes are invalid"
  end

  describe "show/2" do
    test "Responds with user info if the user is found"
    test "Responds with a message indicating user not found"
  end

  describe "update/2" do
    test "Edits, and responds with the user if attributes are valid"
    test "Returns an error and does not edit the user if attributes are invalid"
  end

  test "delete/2 and responds with :ok if the user was deleted"

end
```

ここでは、典型的なJSON APIのために実装する必要がある5つのコントローラーのCRUDアクションを中心としたテストを行っています。モジュールのトップには`HelloWeb.ConnCase`というモジュールを使用しており、テストリポジトリへの接続を提供しています。次に、8つのテストを定義します。indexとdeleteの2つのケースでは、一般的にはドメインルール（またはその欠如）のために失敗することはないため、ハッピーパスのみをテストしています。現実的には、関連するリソースがあっても孤児になったリソースを残すことができない場合や、その他様々な状況で削除に失敗する可能性があります。インデックス上では、フィルタリングや検索などのテストが必要になるかもしれません。また、どちらも認証が必要になる場合があります。

create、show、update は、リソースを見つける方法が必要なため、失敗する典型的な方法(リソースが存在しない場合であったり、パラメーターに無効なデータを提供すること)があります。これらのエンドポイントごとに複数のテストがあるので、それらを`describe`ブロックに入れることはテストを整理するのに良い方法です。

テストを実行してみましょう。

```console
$ mix test test/hello_web/controllers/user_controller_test.exs
```

"Not implemented"と言われる8つの失敗が得られることでしょう。それでよいのです。テストはまだブロックを持っていないのですから。

### 最初のテスト

最初のテストを追加してみましょう。`index/2`からはじめてみます。

```elixir
defmodule HelloWeb.UserControllerTest do
  use HelloWeb.ConnCase

  alias Hello.Accounts

  test "index/2 responds with all Users", %{conn: conn} do

    users = [%{name: "John", email: "john@example.com", password: "john pass"},
             %{name: "Jane", email: "jane@example.com", password: "jane pass"}]

    # create users local to this database connection and test
    [{:ok, user1},{:ok, user2}] = Enum.map(users, &Accounts.create_user(&1))

    response =
      conn
      |> get(Routes.user_path(conn, :index))
      |> json_response(200)

    expected = %{
      "data" => [
        %{ "name" => user1.name, "email" => user1.email },
        %{ "name" => user2.name, "email" => user2.email }
      ]
    }

    assert response == expected
  end
```

ここでは行っていることをみてみましょう。まず`Hello.Accounts`をエイリアスしています。これはリポジトリ操作関数を提供するコンテキストモジュールです。`HelloWeb.ConnCase`モジュールをuseすると、各接続がトランザクションにラップされるように設定し、*なおかつ*、テスト内のすべてのデータベースのインタラクションが同じデータベース接続とトランザクションを使用します。このモジュールはExUnitコンテキストの中で`Phoenix.ConnCase.build_conn/0`使われ、`conn`属性もセットアップします。そして、これをパターンマッチして、各テストケースで使用します。詳細は、`test/support/conn_case.ex`や同様に[Ecto documentation for SQL.Sandbox](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html)をご参照ください。各テストの中に`build_conn/0`呼び出しを入れることもできますが、それを行うにはセットアップブロックを使った方がすっきりします。

indexのテストはその後、コンテキストにフックして`:conn`キーの内容を抽出します。`Hello.Accounts.create_user/1`関数を用いて2人のユーザーを作っています。もう一度言及しておくと、この関数はテスト用のレポにアクセスしていますが、呼び出し際して`conn`変数を渡していないにもかかわらず、同じ接続を使用し、これらの新しいユーザーを同じデータベーストランザクションの中に入れていることに注意してください。次に`conn`は`get`関数にパイプされ、`UserController` indexアクションへの`GET`リクエストを行います。それは期待されるHTTPステータスコードとともに`json_response/2`にパイプされ返されます。これは、すべてが適切に構築されているときにレスポンスボディからJSONを返します。コントローラーアクションが返したいJSONを変数`expected`で表現し、`response`と`expected`が同じであることをアサートしています。

期待するデータは、`"data"`というトップレベルのキーを持つ JSON レスポンスで、リクエストする前に作成したユーザーと一致する`"name"`と`"email"`プロパティを持つユーザーの配列を含みます。また、ユーザーの"password"プロパティがJSONレスポンスに表示されないようにします。

テストを実行すると、`user_path`関数がないというエラーが出ます。

ルーターでは、自動生成ファイルの下部にある`api`スコープのコメントを外し、リソースマクロを使って"/users"パスのルートを生成します。ユーザーを作成したり更新したりするためのフォームを生成するわけではないので、`except: [:new, :edit]`を追加して、これらのエンドポイントを省きます。

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
    resources "/users", UserController, except: [:new, :edit]
  end
end
```

テストを再度実行する前に、`mix phx.routes`を実行して新しいパスを確認してください。デフォルトのページコントローラールートに加えて、6つの新しい"/api"ルートが表示されるはずです。

```console
$ mix phx.routes
Compiling 6 files (.ex)
page_path  GET     /               HelloWeb.PageController :index
user_path  GET     /api/users      HelloWeb.UserController :index
user_path  GET     /api/users/:id  HelloWeb.UserController :show
user_path  POST    /api/users      HelloWeb.UserController :create
user_path  PATCH   /api/users/:id  HelloWeb.UserController :update
           PUT     /api/users/:id  HelloWeb.UserController :update
user_path  DELETE  /api/users/:id  HelloWeb.UserController :delete
```

これで新しいエラーが表示されるはずです。テストを実行すると、`HelloWeb.UserController`がないことがわかります。ファイル`lib/hello_web/controllers/user_controller.ex`を開いて、テスト対象の`index/2`アクションを追加して、そのコントローラーを作成してみましょう。テストの説明では、すべてのユーザを返すようになっています。

```elixir
defmodule HelloWeb.UserController do
  use HelloWeb, :controller
  alias Hello.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

end
```

再度テストを実行すると、失敗したテストではモジュール`HelloWeb.UserView`が利用できないことがわかります。ファイル`lib/hello_web/views/user_view.ex`を作成して追加してみましょう。テストでは、トップキーが`"data"`のJSON形式で、属性`"name"`と`"email"`を持つユーザーの配列を指定しています。

```elixir
defmodule HelloWeb.UserView do
  use HelloWeb, :view

  def render("index.json", %{users: users}) do
    %{data: render_many(users, HelloWeb.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{name: user.name, email: user.email}
  end

end
```

indexのためのビューモジュールは`render_many/4`関数を使っています。[documentation](https://hexdocs.pm/phoenix/Phoenix.View.html#render_many/4)によると、`Enum.map/2`を使うことと"大雑把には等価"であり、内部実装では`Enum.map/2`が直接呼ばれています。`render_many/4`と直接`Enum.map/2`を呼び出すことの大きな違いは、前者にはライブラリ品質のエラーチェックや欠落した値の適切なハンドリングなどの利点があります。また、`render_many/4`には`:as`オプションがあり、これを利用して割り当てマップのキーの名前を変更することができます。デフォルトでは、これはモジュール名(この場合は`:user`)から推測されますが、使用するレンダリング関数に合わせて必要に応じて変更することができます。

そして、テストを実行すると、indexのテストはパスします。

### showアクションのテスト

ここでは`show/2`アクションもカバーしましょう。エラーケースのハンドリングの方法をみることができます。

showのテストは現在このようになっています。

```elixir
  describe "show/2" do
    test "Responds with user info if the user is found"
    test "Responds with a message indicating user not found"
  end
```

下記のコマンドを実行することでこのテストのみを実行させましょう: (もし該当のテストが34行目から始まっていない場合は適宜行数を変更してください)

```console
$ mix test test/hello_web/controllers/user_controller_test.exs:34
```

`show/2`の結果は予想通り、not implementedになっています。成功した`show/2`がどのように見えるかを中心にテストを構築してみましょう。

```elixir
test "Responds with user info if the user is found", %{conn: conn} do
  {:ok, user} = Accounts.create_user(%{name: "John", email: "john@example.com", password: "john pass"})

  response =
    conn
    |> get(Routes.user_path(conn, :show, user.id))
    |> json_response(200)

  expected = %{"data" => %{"email" => user.email, "name" => user.name}}

  assert response == expected
end
```

これは問題ありませんが、少しリファクタリングすることができます。このテストとindexテストの両方ともデータベースにユーザーが必要であることに注意してください。これらのユーザーを何度も何度も作成する代わりに、別の`setup/1`関数を呼び出して、必要に応じてデータベースにユーザーを追加することができます。これを行うには、まずテストモジュールの下部に以下のようなプライベート関数を作成します。

```elixir
defp create_user(_) do
  {:ok, user} = Accounts.create_user(@create_attrs)
  {:ok, user: user}
end
```
次に、カスタム属性として`@create_attrs`をモジュールの上部に下記のように宣言します。

```elixir
alias Hello.Accounts

@create_attrs %{name: "John", email: "john@example.com", password: "john pass"}
```


最後に`describe`ブロックの2行目で`setup/1`を使って関数を実行します。

```elixir
describe "show/2" do
  setup [:create_user]
  test "Responds with user info if the user is found", %{conn: conn, user: user} do

    response =
      conn
      |> get(Routes.user_path(conn, :show, user.id))
      |> json_response(200)

    expected = %{"data" => %{"email" => user.email, "name" => user.name}}

    assert response == expected
  end
  test "Responds with a message indicating user not found"
end
```

`setup`で呼び出される関数は、ExUnitのコンテキスト(このガイドで説明しているコンテキストと混同しないようにしましょう)を受け取り、それを返すときにフィールドを追加することができます。この場合、`create_user`は既存のコンテキストを気にせず(つまりアンダースコアパラメータを指定しているのです)、新しいユーザーをExUnitのコンテキストに`{:ok, user: user}`を返すことによって`user:`というキーで追加します。これで、テストはデータベース接続とこの新しいユーザの両方にExUnitコンテキストからアクセスできるようになります。

最後に、新しい`create_user`関数を使うように`index/2`テストを変更してみましょう。indexのテストでは、*結局のところ*2人のユーザは必要ありません。改訂した`index/2`テストは次のようになります。

```elixir
  describe "index/2" do
    setup [:create_user]
    test "index/2 responds with all Users", %{conn: conn, user: user} do

      response =
        conn
        |> get(Routes.user_path(conn, :index))
        |> json_response(200)

      expected = %{"data" => [%{"name" => user.name, "email" => user.email}]}

      assert response == expected
    end
  end
```

ここでの最大の変更点は、古いテストを別の`describe`ブロックの中にまとめ、indexテストのための`setup/2`コールを置く場所を確保したことです。これで、ExUnitのコンテキストからユーザーにアクセスし、`index/2`のテスト結果からはユーザーが二人ではなく一人だけになることを期待できるようになりました。

`index/2`テストはまだパスするはずですが、`show/2`テストは`HelloWeb.UserController.show/2`アクションが必要だというメッセージでエラーになります。次にこれをUserControllerモジュールに追加してみましょう。

```elixir
defmodule HelloWeb.UserController do
  use HelloWeb, :controller
  alias Hello.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

end
```

`get_user!/1`関数の感嘆符に気づくかもしれません。この慣習は、要求されたユーザーが見つからなかった場合にこの関数がエラーをスローすることを意味しています。また、ここでは投げられたエラーの可能性を適切に処理していないことにも気づくでしょう。TDDでは、テストを通過させるのに十分なコードを書きたいだけです。`show/2`のエラー処理テストにたどり着いたら、さらにコードを追加します。

テストを実行すると、`"show.json"`にパターンマッチする`render/2`関数が必要だと言われるでしょう:

```elixir
defmodule HelloWeb.UserView do
  use HelloWeb, :view

  def render("index.json", %{users: users}) do
    %{data: render_many(users, HelloWeb.UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, HelloWeb.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{name: user.name, email: user.email}
  end

end
```

"show.json"のレンダリングには`render_many/4`のかわりに`render_one/4`を使っていることに気づくでしょう。なぜならは、リストではなく単一のユーザーをレンダリングするのみだからです。

もう一度テストを実行すると、パスします。

### ユーザーが存在しない場合のshowアクションテスト

最後に、`show/2`でユーザーが見つからない場合のケースに取り組んでみましょう。

これを自分で試してみて、何を思いつくか考えてみてください。以下に一つの解決策を以下に示します。

テスト駆動開発のステップを進めて、存在しないユーザーIDを`user_path`に指定すると、ステータスコード404とエラーメッセージを返すテストを追加します。ここでの興味深い問題は存在しないIDをどのように定義するかです。大きな整数を指定してみることもできますが、将来のテストで何千人ものテストユーザが発生してテストが壊れることがないとは言い切れるでしょうか？　大きな整数を使うかわりに、他の方法も使うことができます。データベースのidは1から始まり無限に増加していく傾向があります。負の整数は完全に有効な整数ではありますが、データベースのIDとしては決して使われることはありません。それで"取得不可能な "ユーザIDとして-1を選択します。こうすることでいつもテストは*失敗するでしょう。*

```elixir
test "Responds with a message indicating user not found", %{conn:  conn} do
  conn = get(conn, Routes.user_path(conn, :show, -1))

  assert text_response(conn, 404) =~ "User not found"
end
```

このリソースが見つからなかったことを要求元に通知するために、404というHTTPステータスコードと、それに付随するエラーメッセージが必要です。ステータスコードが404であり、レスポンスボディーが付随するエラーメッセージと一致することを保証するために、[`json_response/2`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html#json_response/2)の代わりに[`text_response/2`](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html#text_response/2)を使用していることに注意してください。このテストを実行して、何が起こるかを確認することができます。データベースにそのようなユーザが存在しないため、`Ecto.NoResultsError`がスローされることがわかるはずです。

コントローラーアクションはEctoによって投げられたエラーを処理する必要があります。ここでは2つの選択肢があります。デフォルトでは、これは[phoenix_ecto](https://github.com/phoenixframework/phoenix_ecto)ライブラリによって処理され、404を返します。しかし、カスタムのエラーメッセージを表示したい場合は、Ectoのエラーをスローしない新しい`get_user/1`関数を作成することができます。この例では、2番目のパスを取り、新しい`get_user/1`関数をちょうど`get_user!/1`関数の直前で`lib/hello/accounts.ex`ファイルに実装します。

```elixir
@doc """
Gets a single `%User{}` from the data store where the primary key matches the
given id.

Returns `nil` if no result was found.

## Examples

    iex> get_user(123)
    %User{}

    iex> get_user(456)
    nil

"""
def get_user(id), do: Repo.get(User, id)
```

この関数は`Ecto.Repo.get/3`のまわりを薄くラップしたものであり、ユーザーが見つかれば`%User{}`を返し、ユーザーが見つからなければ`nil`を返します。次に`show/2`関数でスローしないバージョンを使うように変更して、2つの取りうる値をハンドリングします。

```elixir
def show(conn, %{"id" => id}) do
  case Accounts.get_user(id) do
    nil ->
      conn
      |> put_status(:not_found)
      |> text("User not found")

    user ->
      render(conn, "show.json", user: user)
  end
end
```

case文の最初のブランチでは結果が`nil`のケースを扱います。まず、`Plug.Conn`から[`put_status/2`](https://hexdocs.pm/plug/Plug.Conn.html#put_status/2)関数を使い、希望するエラーステータスを設定します。[Plug.Conn.Status documentation](https://hexdocs.pm/plug/Plug.Conn.Status.html)に利用できるステータスコードの完全なリストを参照することができ、今回期待する"404"ステータスコードに対応する`:not_found`を設定しています。そうして、[`text/2`](https://hexdocs.pm/phoenix/Phoenix.Controller.html#text/2)を使うことでテキストレスポンスを返しています。

case文の2番目のブランチはすでに実装済みの"ハッピーパス"を処理します。Phoenixはまたアクションの中で"ハッピーパス"のみを実装する機能があり、`Phoenix.Controller.action_fallback/1`を使います。これはエラーハンドリングコードを共通化することに役立ちます。[コントローラー](../controllers.html#アクションフォールバック)の「アクションフォールバック」節で取り扱ったaction_fallbackを使ってshowアクションをリファクタすることが望ましいかもしれません。

これらを実装すると、テストはパスします。

コントローラーテストの残りの実装は練習としてあなたに残しておきます。どこから手をつけていいかわからない場合は、Phoenix JSON ジェネレータを使用して、どのようなテストが自動的に生成されるかを確認するとよいでしょう。

Happy testing!
テストに幸あれ!