---
layout: 1.4/layout
version: 1.4
group: guides
title: コンテキスト
nav_order: 12
hash: a9334550d81c14ba656d49351af6d25f0a3a7587
---
# コンテキスト
これまでに、ページを構築し、ルーターを介してコントローラーのアクションを接続し、Ectoがどのようにしてデータをバリデートし、永続化するかを学んできました。今度は、より大きなElixirアプリケーションと相互作用するWeb向けの機能を書くことで、すべてを結びつける時が来ました。

Phoenixプロジェクトを構築する際には、まず第一にElixirアプリケーションを構築します。Phoenixの仕事は、ElixirアプリケーションにWebインターフェイスを提供することです。当然、アプリケーションはモジュールと関数で構成されますが、アプリケーションを設計する際には、いくつかの関数を持つモジュールを定義するだけでは不十分です。コードを書くときにアプリケーションの設計を考えることが重要です。では、その方法を見てみましょう。

> このガイドの読み方:
コンテキストジェネレーターを使用することは、初心者から中級者まで、Elixirのプログラマーがアプリケーションを思慮深く設計しながら、すぐに使いこなせるようになるための素晴らしい方法です。このガイドでは、このような読者に焦点を当てています。一方、経験豊富な開発者の方は、アプリケーション設計に関する特別で繊細な議論をすることで、より多くの成果を得ることができるかもしれません。このような読者のために、ガイドの最後によくある質問(FAQ)セクションを設けました。これらはガイド全体で行われたいくつかの設計上の決定に異なる視点をもたらします。初心者の方は、FAQセクションをスキップして、より深く掘り下げる準備ができたときに、あとで戻ってくることができます。

## 設計について考える

コンテキストは、関連する関数を公開したり、グループ化したりする専用モジュールです。たとえば、`Logger.info/1` や `Stream.map/2` など、Elixirの標準ライブラリを呼び出すときはいつでも、異なるコンテキストにアクセスしていることになります。内部的には、Elixirのロガーは複数のモジュールで構成されていますが、それらのモジュールと直接やりとりすることはありません。私たちは `Logger` モジュールをコンテキストと呼んでいますが、これは正確にはすべてのロギング機能を公開し、グループ化しているからです。

PhoenixプロジェクトはElixirや他のElixirプロジェクトと同じように構造化されています。我々はコードをコンテキストに分割します。コンテキストは、投稿やコメントなどの関連機能をグループ化し、データアクセスやデータバリデーションなどのパターンをカプセル化します。コンテキストを使うことで、システムを管理しやすい独立した部分に分離できます。

これらのアイデアを使って、ウェブアプリケーションを構築してみましょう。私たちの目標は、ユーザーシステムと、ページコンテンツの追加や編集を行うための基本的なコンテンツ管理システムを構築することです。さあ、始めましょう。

### アカウントコンテキストを追加する
ユーザーアカウントは、プラットフォーム全体で広範囲に及ぶことが多いので、明確に定義されたインターフェースを書くことを前もって考えることが重要です。このことを念頭に置いて、私たちの目標は、ユーザーアカウントの作成、更新、削除を処理し、ユーザーのクレデンシャルを認証するアカウントAPIを構築することです。最初は基本的な機能から始めますが、あとで認証を追加していくうちに、しっかりとした基礎から始めることで、機能を追加しながらアプリケーションを自然に成長させていくことができることがわかります。

Phoenixには `phx.gen.html`, `phx.gen.json`, `phx.gen.context` ジェネレーターが含まれており、アプリケーションの機能をコンテキストに分離するという考え方を適用します。これらのジェネレーターは、アプリケーションを成長させるためにPhoenixが適切な方向に誘導してくれる間に、最初の一歩を踏み出すのに最適な方法です。これらのツールを新しいユーザーアカウントのコンテキストで使用してみましょう。

コンテキストジェネレーターを実行するためには、構築しようとしている関連した機能をグルーピングするモジュール名を考える必要があります。[Ectoガイド](ecto.html)では、ユーザースキーマをバリデートして永続化するためにChangesetsとReposを使う方法を見ましたが、これをアプリケーション全体に統合していませんでした。実際、アプリケーション内の「ユーザー」がどこに存在すべきかについてはまったく考えていませんでした。一歩下がって、システムのさまざまな部分について考えてみましょう。私たちのプロダクトにはユーザーがいることを知っています。ユーザーと一緒に、アカウントのログインクレデンシャルやユーザー登録のようなものもあります。システム内の `Accounts` コンテキストは、ユーザーの機能性を実現するための自然な場所です。

> 物事のネーミングは難しいです。システム内でグループ化された機能がまだはっきりしていないときにコンテキスト名を考えようとしたときに行き詰った場合は、単に作成しているリソースの複数形を使うことができます。たとえば、ユーザーを管理するための `Users` コンテキストなどです。アプリケーションを成長させ、システムの各部分が明確になってきたら、後からコンテキストの名前をより洗練された名前に変更することができます。

ジェネレーターを使用する前に、Ectoガイドで行った変更を元に戻し、ユーザースキーマを適切な場所を与える必要があります。これらのコマンドを実行して、以前の作業を元に戻します。

```console
$ rm lib/hello/user.ex
$ rm priv/repo/migrations/*_create_users.exs
```

次に、先ほど削除したテーブルも破棄するように、データベースをリセットしてみましょう。

```console
$ mix ecto.reset
Generated hello app
The database for Hello.Repo has been dropped
The database for Hello.Repo has been created

14:38:37.418 [info]  Already up
```

これでアカウントコンテキストを作成する準備が整いました。タスク `phx.gen.html` を使用します。これはユーザーの作成、更新、削除のためのEctoアクセスをまとめるコンテキストモジュールを作成するもので、コントローラーやWebインターフェイスのテンプレートなどのWebファイルをコンテキストに取り込みます。プロジェクトのルートで以下のコマンドを実行してください。

```console
$ mix phx.gen.html Accounts User users name:string \
username:string:unique

* creating lib/hello_web/controllers/user_controller.ex
* creating lib/hello_web/templates/user/edit.html.eex
* creating lib/hello_web/templates/user/form.html.eex
* creating lib/hello_web/templates/user/index.html.eex
* creating lib/hello_web/templates/user/new.html.eex
* creating lib/hello_web/templates/user/show.html.eex
* creating lib/hello_web/views/user_view.ex
* creating test/hello_web/controllers/user_controller_test.exs
* creating lib/hello/accounts/user.ex
* creating priv/repo/migrations/20170629175236_create_users.exs
* creating lib/hello/accounts.ex
* injecting lib/hello/accounts.ex
* creating test/hello/accounts_test.exs
* injecting test/hello/accounts_test.exs

Add the resource to your browser scope in lib/hello_web/router.ex:

    resources "/users", UserController


Remember to update your repository by running migrations:

    $ mix ecto.migrate

```

Phoenixは期待通りに`lib/hello_web/`にWebファイルを生成しました。また、コンテキストファイルは `lib/hello/accounts.ex` ファイルの中に、ユーザースキーマは同じ名前のディレクトリに生成されていることがわかります。`lib/hello` と `lib/hello_web` の違いに注意してください。アカウント機能の公開APIとして機能する `Accounts` モジュールと、ユーザーアカウントデータをキャストしてバリデートするためのEctoスキーマである `Accounts.User` 構造体があります。PhoenixはWebテストとコンテキストテストも提供してくれました。これらは後ほど見ます。とりあえず、コンソールの指示にしたがって `lib/hello_web/router.ex` にルートを追加してみましょう。

```elixir
  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
+   resources "/users", UserController
  end
```

新しいルートができたので、Phoenixは `mix ecto.migrate` を実行してレポを更新するように促してくれます。これを実行してみましょう。

```console
$ mix ecto.migrate

[info]  == Running Hello.Repo.Migrations.CreateUsers.change/0 forward

[info]  create table users

[info]  create index users_username_index

[info]  == Migrated in 0.0s
```

生成されたコードへ飛び込む前に、`mix phx.server`でサーバーを起動し、[http://localhost:4000/users](http://localhost:4000/users)へアクセスしてみましょう。"New User" リンクをたどって、何も入力せずに "Submit" ボタンをクリックしてみましょう。すると、以下のような出力が表示されるはずです。

```
Oops, something went wrong! Please check the errors below.
```

フォームを送信すると、入力欄と並んですべてのバリデーションエラーが表示されます。いいですね！すぐに使えて、コンテキストジェネレーターがスキーマフィールドをフォームテンプレートにインクルードしたので、必須入力に対するデフォルトのバリデーションが有効になっていることがわかります。ユーザーデータの例を入力して、フォームを再送信してみましょう。

```
User created successfully.

Show User
Name: Chris McCord
Username: chrismccord
```

"Back"リンクをたどると、すべてのユーザーのリストが表示され、その中に先ほど作成したものが含まれているはずです。同様に、このレコードを更新したり、削除したりできます。ブラウザ上での動作を確認したので、生成されたコードを見てみましょう。

## ジェネレーターで始める
この小さな `phx.gen.html` コマンドは、驚くべきパンチを持っています。ユーザーの作成、更新、削除のための多くの機能がすぐに使えるようになりました。これは完全な機能を備えたアプリではありませんが、ジェネレーターはまず第一に学習ツールであり、実際の機能を構築するための出発点であることを覚えておいてください。コード生成ですべての問題を解決することはできませんが、Phoenixのインとアウトを教えてくれますし、アプリケーションを設計する際の適切なマインドセットに向けて後押ししてくれます。

まず、`lib/hello_web/controllers/user_controller.ex` で生成された `UserController` を見てみましょう。

```elixir
defmodule HelloWeb.UserController do
  use HelloWeb, :controller

  alias Hello.Accounts
  alias Hello.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  ...
end
```

コントローラーがどのように動作するかは[controller guide](controllers.html)で見てきたので、このコードはそれほど驚くようなものではないでしょう。注目すべきは、コントローラーが `Accounts` コンテキストにどのように呼び出しているかということです。`index` アクションが `Accounts.list_users/0` でユーザーのリストを取得し、`create` アクションが `Accounts.create_user/1` でユーザーを保持していることがわかります。アカウントのコンテキストをまだ見ていないので、ユーザーの取得や作成がどのように行われているのかはまだわかりません - *ただし、ここがポイントです*。私たちのPhoenixコントローラーは、より大きなアプリケーションへのWebインターフェースです。ユーザーがどのようにしてデータベースからフェッチされたり、ストレージに保存されたりするかの詳細は気にするべきではありません。私たちが気にするのは、アプリケーションが私たちのために仕事をするように指示することだけです。ビジネスロジックやストレージの詳細は、アプリケーションのウェブ層から切り離されているので、これは素晴らしいことです。後日、SQLクエリの代わりに全文検索エンジンに移行してユーザーを取得したとしても、コントローラーを変更する必要はありません。同様に、チャンネルやMixタスク、CSVをインポートする実行時間の長いプロセスなど、アプリケーション内の他のインターフェイスからコンテキストコードを再利用できます。

`create`アクションの場合、ユーザーの作成に成功したら、`Phoenix.Controller.put_flash/3`を使って成功メッセージを表示し、`user_path`のshowページにリダイレクトします。逆に、`Accounts.create_user/1`が失敗した場合は、`"new.html"`テンプレートをレンダリングし、エラーメッセージを出力するテンプレートへEctoのチェンジセットを渡します。

次に、`lib/hello/accounts.ex`にある `Accounts` のコンテキストを確認してみましょう。

```elixir
defmodule Hello.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Hello.Repo

  alias Hello.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end
  ...
end
```

このモジュールは、システム内のすべてのアカウント機能のための公開APIとなります。たとえば、ユーザーのアカウント管理に加えて、ユーザーのログインクレデンシャル、アカウントの設定、パスワードリセットなどを扱うことがあります。関数 `list_users/0` を見てみると、ユーザー取得の詳細を見ることができます。そして、それは超単純です。`Repo.all(User)`を呼び出しています。Ectoのレポクエリがどのように動作するかは[Ectoガイド](ecto.html)で見たので、この呼び出しは見覚えがあるはずです。私たちの `list_users` 関数は、コードの *意図* - つまり、ユーザーをリストアップするため - を明示する一般化された関数です。PostgreSQLデータベースからユーザーを取得するためにレポを使用するという意図の詳細は、呼び出し元からは隠されています。これは、Phoenixジェネレーターを使用する際に繰り返し見られる共通のテーマです。Phoenixは、アプリケーションのどこに異なる責任があるのかを考え、それらの異なる領域を、詳細をカプセル化しながら、コードの意図を明確にする名前のついたモジュールや関数でまとめることを促します。

データがどのようにして取得されるかはわかりましたが、ユーザーはどのようにして永続化されるのでしょうか？関数 `Accounts.create_user/1` を見てみましょう。

```elixir
  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
```

ここではコードよりもドキュメントの方が多いですが、いくつかの強調すべき重要なことがあります。まず、Ectoレポがデータベースへのアクセスに使用されていることが再確認できます。おそらく、`User.changeset/2`への呼び出しにもお気づきでしょう。以前にチェンジセットについて話しましたが、今回はコンテキストの中で動作しているのを確認できます。

`lib/hello/accounts/user.ex` の `User` スキーマを開くと、すぐに見覚えがあります。

```elixir
defmodule Hello.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hello.Accounts.User


  schema "users" do
    field :name, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> unique_constraint(:username)
  end
end
```
これは以前に `mix phx.gen.schema` タスクを実行したときに見たものと同じですが、ここでは `changeset/2` 関数の上に `@doc false` が表示されています。これは、この関数はパブリックで呼び出し可能ですが、パブリックコンテキストAPIの一部ではないことを示しています。チェンジセットを作成する呼び出し元はコンテキストAPIを介して行います。たとえば、`Accounts.create_user/1` は `User.changeset/2` を呼び出してユーザー入力からチェンジセットを構築します。コントローラーアクションなどの呼び出し元は `User.changeset/2` に直接アクセスしません。ユーザーチェンジセットとのやりとりはすべて、パブリックな `Accounts` コンテキストを介して行われます。

## コンテキスト内のリレーション

私たちの基本的なユーザーアカウント機能は素晴らしいものですが、ユーザーのログインクレデンシャルをサポートすることで、さらにレベルアップしていきましょう。完全な認証システムを実装するわけではありませんが、そのようなシステムを成長させるための良いスタートを切ることができます。多くの認証ソリューションでは、ユーザーのクレデンシャルとアカウントを一対一の方法で結びつけていますが、これはしばしば問題を引き起こします。たとえば、ソーシャルログインやリカバリーメールアドレスなど、異なるログイン方法をサポートすると、大きなコード変更が発生します。アカウントごとに1つのクレデンシャルの追跡を開始し、後から簡単に多くの機能をサポートできるように、クレデンシャルの関連付けを設定してみましょう。

今のところ、ユーザーのクレデンシャルには電子メールの情報のみが含まれています。私たちの最初の仕事は、アプリケーションの中でクレデンシャルをどこに置くかを決めることです。ユーザーアカウントを管理する `Accounts` コンテキストがあります。ここでは、ユーザークレデンシャルが自然に適合します。Phoenixはまた、既存のコンテキスト内にコードを生成することができるので、コンテキストに新しいリソースを追加するのも簡単です。プロジェクトのルートで以下のコマンドを実行してください。

> 2つのリソースが同じコンテキストに属しているかどうかを判断するのが難しい場合があります。そのような場合には、リソースごとに異なるコンテキストを使用し、必要に応じてあとでリファクタリングしてください。そうしないと、関連性の低いエンティティの大規模なコンテキストが簡単にできてしまいます。言い換えれば、わからない場合は、リソース間の明示的なモジュール（コンテキスト）を選ぶべきです。

```console
$ mix phx.gen.context Accounts Credential credentials \
email:string:unique user_id:references:users

* creating lib/hello/accounts/credential.ex
* creating priv/repo/migrations/20170629180555_create_credentials.exs
* injecting lib/hello/accounts.ex
* injecting test/hello/accounts_test.exs

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

今回は `phx.gen.context` タスクを利用しました。これは `phx.gen.html` と似ていますが、ウェブファイルを生成しません。すでにユーザーを管理するためのコントローラーとテンプレートがあるので、新しいクレデンシャル機能を既存のWebフォームに統合することができます。

出力から、Phoenixが `Accounts.Credential` スキーマ用の `accounts/credential.ex` ファイルとマイグレーションを生成したことがわかります。phoenixは、既存の `accounts.ex` コンテキストファイルとテストファイルにコードを注入していると述べています。私たちの `Accounts` モジュールはすでに存在しているので、Phoenixはここにコードを注入することを知っています。

マイグレーションを実行する前に、ユーザーアカウントのクレデンシャルのデータの整合性を確保するために、生成されたマイグレーションに1つ変更を加える必要があります。この例では、親ユーザーが削除されたときにユーザーのクレデンシャルが削除されるようにしたいと考えています。`priv/repo/migrations/`にある `*_create_credentials.exs` マイグレーションファイルに以下の変更を加えてください。

```diff
  def change do
    create table(:credentials) do
      add :email, :string
-     add :user_id, references(:users, on_delete: :nothing)
+     add :user_id, references(:users, on_delete: :delete_all),
+                   null: false

      timestamps()
    end

    create unique_index(:credentials, [:email])
    create index(:credentials, [:user_id])
  end
```

`on_delete` オプションを `:nothing` から `:delete_all` に変更しました。これにより、データベースからユーザーが削除されたときに、指定したユーザーのすべてのクレデンシャルを削除する外部キー制約を生成します。同様に、`null: false` を渡すことで、既存のユーザーなしでクレデンシャルを作成できないようにしています。データベース制約を使用することで、アドホックでエラーが発生しやすいアプリケーションロジックに頼るのではなく、データベースレベルでデータの整合性を強制することができます。

次に、Phoenixの指示通りにデータベースをマイグレートしてみましょう。

```console
$ mix ecto.migrate
mix ecto.migrate
Compiling 2 files (.ex)
Generated hello app

[info]  == Running Hello.Repo.Migrations.CreateCredentials.change/0 forward

[info]  create table credentials

[info]  create index credentials_email_index

[info]  create index credentials_user_id_index

[info]  == Migrated in 0.0s
```

Webレイヤーにクレデンシャルを統合する前に、コンテキストにユーザーとクレデンシャルの関連付け方を知らせる必要があります。まず、`lib/hello/accounts/user.ex`を開き、以下の関連付けを追加します。

```elixir
+ alias Hello.Accounts.Credential


  schema "users" do
    field :name, :string
    field :username, :string
+   has_one :credential, Credential

    timestamps()
  end


```

`Ecto.Schema` の `has_one` マクロを使用して、親ユーザーと子クレデンシャルの関連付け方法をEctoに知らせました。次に、`accounts/credential.ex`に逆方向のリレーションを追加してみましょう。

```elixir
+ alias Hello.Accounts.User


  schema "credentials" do
    field :email, :string
-   field :user_id, :id
+   belongs_to :user, User

    timestamps()
  end

```

`belongs_to` マクロを使用して、子リレーションを親の `User` にマッピングしました。スキーマの関連付けを設定したので、`accounts.ex` を開き、生成された `list_users` と `get_user!`関数に次の変更を加えましょう。

```elixir
  def list_users do
    User
    |> Repo.all()
    |> Repo.preload(:credential)
  end

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload(:credential)
  end
```

`list_users/0` と `get_user!/1` を書き換えて、ユーザーを取得するたびにクレデンシャルアソシエーションをプリロードするようにしました。レポのプリロード機能はスキーマのアソシエーションデータをデータベースから取得し、スキーマ内に配置します。`list_users`のクエリのようにコレクションを操作する場合、Ectoは1つのクエリで効率的に関連付けをプリロードすることができます。これにより、`%Accounts.User{}` 構造体を常にクレデンシャルを含むように表現することができ、呼び出し元が余分なデータを取得することを気にする必要がありません。

次に、ユーザーフォームにクレデンシャルの入力欄を追加して、新しい機能をウェブに公開してみましょう。`lib/hello_web/templates/user/form.html.eex` を開き、送信ボタンの上にある新しいクレデンシャルフォームグループを入力します。


```eex
  ...
+ <div class="form-group">
+   <%= inputs_for f, :credential, fn cf -> %>
+     <%= label cf, :email %>
+     <%= text_input cf, :email %>
+     <%= error_tag cf, :email %>
+   <% end %>
+ </div>

  <%= submit "Submit" %>
```

`Phoenix.HTML` の `inputs_for` 関数を使って、親フォームに入れ子になったフィールドを追加しました。入れ子になったinputの中に、クレデンシャルのメールアドレスフィールドをレンダリングし、他のinputと同様に `label` と `error_tag` ヘルパーを含めました。

次に、ユーザーのメールアドレスをユーザーのshowテンプレートに表示してみましょう。以下のコードを `lib/hello_web/templates/user/show.html.eex` に追加します。

```eex
  ...
+ <li>
+   <strong>Email:</strong>
+   <%= @user.credential.email %>
+ </li>
</ul>

```

さて、[http://localhost:4000/users/new](http://localhost:4000/users/new)にアクセスすると、新しいemailのinputが表示されますが、ユーザーを保存しようとすると、メールフィールドが無視されていることがわかります。空白でデータが保存されていないことを伝えるバリデーションは実行されず、最後に例外 `(UndefinedFunctionError) function nil.email/0 is undefined or private` が発生します。何が原因なのでしょうか？

Ectoの `belongs_to` と `has_one` のアソシエーションを使用して、コンテキストレベルでのデータの関連付けを行いましたが、これはウェブ上のユーザーによる入力から切り離されていることを覚えておいてください。ユーザーの入力をスキーマのアソシエーションに関連付けるには、これまでに他のユーザー入力を処理してきた方法（チェンジセット）で処理する必要があります。ジェネレーターによって追加されたCredentialのエイリアスを削除し、`Accounts` コンテキスト内の `alias Hello.Accounts.User`, `create_user/1`, `update_user/2` 関数を変更して、入れ子になったクレデンシャル情報を持つユーザー入力をキャストできるチェンジセットを構築します。

```elixir
- alias Hello.Accounts.User
+ alias Hello.Accounts.{User, Credential}
  ...

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
+   |> Ecto.Changeset.cast_assoc(:credential, with: &Credential.changeset/2)
    |> Repo.update()
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
+   |> Ecto.Changeset.cast_assoc(:credential, with: &Credential.changeset/2)
    |> Repo.insert()
  end
  ...

- alias Hello.Accounts.Credential
```

ユーザーチェンジセットを `Ecto.Changeset.cast_assoc/3` にパイプするように関数を更新しました。Ectoの `cast_assoc/3` は、ユーザーの入力をリレーションにキャストする方法をチェンジセットに伝えることができます。また、`:with` オプションを使って `Credential.changeset/2` 関数を使ってデータをキャストするようにEctoに指示しました。この方法では、`Credential.changeset/2` で行うバリデーションは `User` チェンジセットを保存する際に適用されます。

最後に、[http://localhost:4000/users/new](http://localhost:4000/users/new)にアクセスして空のメールアドレスを保存しようとすると、適切な検証エラーメッセージが表示されます。有効な情報を入力した場合、データは適切にキャストされ、永続化されます。

```
Show User
Name: Chris McCord
Username: chrismccord
Email: chris@example.com
```

まだあまり見ていませんが、動作しています。コンテキスト内にリレーションを追加し、データベースによってデータの整合性を強化しました。悪くないですね。引き続き構築を続けていきましょう。

## アカウント関数を追加する

これまで見てきたように、コンテキストモジュールは、関連する機能を公開したり、グループ化したりする専用モジュールです。Phoenixは `list_users` や `update_user` などの汎用的な関数を生成しますが、これらはビジネスロジックやアプリケーションを成長させるための基礎となるだけです。実際の機能を使って `Accounts` コンテキストを拡張するために、アプリケーションの明白な問題に取り組んでみましょう。システムでクレデンシャルを持つユーザーを作成することはできますが、そのユーザーはクレデンシャルを使ってサインインする方法がありません。完全なユーザー認証システムを構築することはこのガイドの範囲を超えていますが、現在のユーザーのセッションを追跡できる基本的な電子メールのみのサインインページから始めてみましょう。これにより、`Accounts` のコンテキストを拡張することに焦点を当てながら、完全な認証ソリューションを構築するための良いスタートを切ることができます。

まず、何を達成したいかを表す関数名を考えてみましょう。メールアドレスでユーザーを認証するためには、そのユーザーを検索し、入力されたクレデンシャルが有効であることを確認する方法が必要です。これは `Accounts` コンテキストで単一の関数を公開することで実現できます。

    > user = Accounts.authenticate_by_email_password(email, password)


いい感じですね。コードの意図を明らかにする説明的な名前がベストです。この関数は、それがどのような目的を果たすのかを明確にし、呼び出し元が内部の詳細に気づかないようにしてくれます。次のように `lib/hello/accounts.ex` ファイルに追加してください。

```elixir
def authenticate_by_email_password(email, _password) do
  query =
    from u in User,
      inner_join: c in assoc(u, :credential),
      where: c.email == ^email

  case Repo.one(query) do
    %User{} = user -> {:ok, user}
    nil -> {:error, :unauthorized}
  end
end
```

ここでは `authenticate_by_email_password/2` 関数を定義しました。今のところパスワードフィールドを破棄しますが、アプリケーションの構築を続けると、[Guardian](https://github.com/ueberauth/guardian) や [comeonin](https://github.com/riverrun/comeonin) のようなツールを統合することができます。この関数で必要なのは、クレデンシャルに一致するユーザーを見つけ、`%Accounts.User{}` 構造体を `:ok` タプルで返すか、`{:error, :unauthorized}` 値を返して、呼び出し元に認証の試みが失敗したことを知らせることです。

コンテキストからユーザーを認証できるようになったので、ログインページをウェブレイヤーに追加してみましょう。まず、`lib/hello_web/controllers/session_controller.ex` に新しいコントローラーを作成します。

```elixir
defmodule HelloWeb.SessionController do
  use HelloWeb, :controller

  alias Hello.Accounts

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: "/")
      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "Bad email/password combination")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
```

アプリケーションにサインイン・サインアウトしたユーザーを処理するために `SessionController` を定義しました。`new` アクションは単純に"new session"フォームをレンダリングし、コントローラーのcreateアクションにPOSTします。`create`では、フォームフィールドをパターンマッチし、先ほど定義した `Accounts.authenticate_by_email_password/2` を呼び出します。成功すれば、`Plug.Conn.put_session/3`を使って認証されたユーザーIDをセッションに入れ、ウェルカムメッセージを表示してホームページにリダイレクトします。また、リダイレクトの前に `configure_session(conn, renew: true)` を呼び出して、[セッション固定攻撃](https://www.owasp.org/index.php/Session_fixation)を避けるようにしています。認証に失敗した場合は、フラッシュエラーメッセージを追加し、サインインページにリダイレクトして再チャレンジしてもらうようにしています。コントローラーを完成させるために、`delete` アクションをサポートしています。これは単に `Plug.Conn.configure_session/2` を呼び出すだけで、セッションを削除してホームページにリダイレクトします。

次に、`lib/hello_web/router.ex`にセッションルートを設定してみましょう。


```elixir
  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/users", UserController
+   resources "/sessions", SessionController, only: [:new, :create, :delete],
                                              singleton: true
  end
```

`resources` を用いて `"/session"` パスの下に一連のルートを生成しました。今回は `:new`, `:create`, `:delete` アクションだけをサポートする必要があるので、生成するルートを制限するために `:only` オプションを渡したことを除いては、他のルートに対しても同様の処理を行っています。また、`singleton: true` オプションも使用しました。これはすべてのRESTfulルートを定義しますが、URLにリソースIDを渡す必要はありません。アクションは常にシステム内の「現在の」ユーザーにスコープされているため、URLにIDを渡す必要はありません。IDは常にセッション内にあります。ルータを完成させる前に、認証プラグをルータに追加してみましょう。これはユーザーが新しいセッションコントローラーを使ってサインインした後に、特定のルートをロックダウンできるようにするものです。以下の関数を `lib/hello_web/router.ex` に追加します。

```elixir
  defp authenticate_user(conn, _) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Login required")
        |> Phoenix.Controller.redirect(to: "/")
        |> halt()
      user_id ->
        assign(conn, :current_user, Hello.Accounts.get_user!(user_id))
    end
  end
```

ルータに `authenticate_user/2` プラグを定義しました。これは単に `Plug.Conn.get_session/2` を使ってセッションの `:user_id` をチェックします。見つかった場合は、ユーザーが認証済みであることを示していますので、`Hello.Accounts.get_user!/1` を呼び出して `:current_user` をconnectionのassignsに入れます。セッションを持っていない場合は、フラッシュエラーメッセージを追加してホームページにリダイレクトし、`Plug.Conn.halt/1`を使って下流のプラグを停止させます。この新しいプラグはまだ使いませんが、認証されたルートを追加するときにすぐに利用できます。

最後に、ログインフォームのテンプレートをレンダリングするための `SessionView` が必要です。新しいファイルを `lib/hello_web/views/session_view.ex:` に作成します。

```elixir
defmodule HelloWeb.SessionView do
  use HelloWeb, :view
end
```

次に、`lib/hello_web/templates/session/new.html.eex`に新しいテンプレートを追加します。

```eex
<h1>Sign in</h1>

<%= form_for @conn, Routes.session_path(@conn, :create), [method: :post, as: :user], fn f -> %>
  <div class="form-group">
    <%= text_input f, :email, placeholder: "Email" %>
  </div>

  <div class="form-group">
    <%= password_input f, :password, placeholder: "Password" %>
  </div>

  <div class="form-group">
    <%= submit "Login" %>
  </div>
<% end %>

<%= form_for @conn, Routes.session_path(@conn, :delete), [method: :delete, as: :user], fn _ -> %>
  <div class="form-group">
    <%= submit "logout" %>
  </div>
<% end %>
```

シンプルにするために、このテンプレートにサインインフォームとサインアウトフォームの両方を追加しました。サインインフォームでは、`@conn` を直接 `form_for` に渡し、フォームアクションを `session_path(@conn, :create)` に指定します。また、`as: :user` オプションを渡すことで、フォームのパラメーターを `"user"` キーで囲むようにします。次に、`text_input` と `password_input` 関数を使って `"email"` と `"password"` パラメーターを送信します。

ログアウトするためには、単に `DELETE` HTTPメソッドをサーバーのセッション削除パスに送信するフォームを定義しただけです。さて、[http://localhost:4000/sessions/new](http://localhost:4000/sessions/new)のサインインページにアクセスして、不正なメールアドレスを入力すると、フラッシュメッセージが表示されるはずです。有効なメールアドレスを入力すると、成功のフラッシュ通知とともにホームページにリダイレクトされます。

これで認証が完了したので、次の機能の開発に向けての準備が整いました。

## コンテキスト間の依存

さて、ユーザーアカウントとクレデンシャルの機能の始まりができたので、アプリケーションの他の主な機能であるページコンテンツの管理に取り掛かりましょう。コンテンツ管理システム (CMS) をサポートして、作者がサイトのページを作成したり、編集したりできるようにしたいと考えています。CMSの機能を使って `Accounts` のコンテキストを拡張することもできますが、一歩下がってアプリケーションを分離して考えてみると、それがフィットしないことがわかります。アカウントシステムはCMSシステムをまったく気にするべきではありません。私たちの `Accounts` コンテキストの責任はユーザーとそのクレデンシャルを管理することであって、ページのコンテンツ変更を扱うことではありません。これらの責任を処理するために別のコンテキストが必要なのは明らかです。これを `CMS` と呼びましょう。

CMSの基本的な業務を処理するための `CMS` コンテキストを作成してみましょう。コードを書く前に、以下のようなCMSの機能要件があると仮定してみましょう。

1. ページの作成と更新
2. ページは、変更を公開する責任のある著者に属する
3. 著者情報はページと一緒に表示し、著者の経歴やCMS内での役割などの情報（`"編集者"`, `"執筆者"`, `"インターン"`など）を含める

説明から、ページ情報を保存するために `Page` リソースが必要であることは明らかです。著者情報はどうでしょうか？既存の `Accounts.User` スキーマを拡張して、経歴やロールなどの情報を含めることはできますが、コンテキストに設定した責任に違反することになります。なぜアカウントシステムが著者情報を認識しなければならないのでしょうか? さらに悪いことに、"role"のようなフィールドでは、システム内のCMSのロールがアプリケーションの他のアカウントロールと競合したり、混同されたりする可能性があります。もっと良い方法があります。

「ユーザー」を持つアプリケーションは、当然のことながらユーザー駆動型のものが多いです。結局のところ、私たちのソフトウェアは通常、何らかの方法で人間のエンドユーザーによって使用されることを想定して設計されています。プラットフォーム全体のすべてのフィールドと責任を追跡するために `Accounts.User` 構造体を拡張するのではなく、その機能を所有するモジュールに責任を持たせた方が良いでしょう。この場合、`CMS.Author` 構造体を作成して、CMSに関連する著者固有のフィールドを保持することができます。これで、"role"や "bio"のようなフィールドをここに自然に配置することができます。同様に、私たちはアプリケーションの中で、すべての人にすべてを提供しなければならないシステム内の単一の `%User{}` ではなく、私たちが運用しているドメインに適した特化したデータ構造を手に入れることができます。

計画が決まったので、作業に取り掛かりましょう。次のコマンドを実行して、新しいコンテキストを生成します。

```
$ mix phx.gen.html CMS Page pages title:string body:text \
views:integer --web CMS

* creating lib/hello_web/controllers/cms/page_controller.ex
* creating lib/hello_web/templates/cms/page/edit.html.eex
* creating lib/hello_web/templates/cms/page/form.html.eex
* creating lib/hello_web/templates/cms/page/index.html.eex
* creating lib/hello_web/templates/cms/page/new.html.eex
* creating lib/hello_web/templates/cms/page/show.html.eex
* creating lib/hello_web/views/cms/page_view.ex
* creating test/hello_web/controllers/cms/page_controller_test.exs
* creating lib/hello/cms/page.ex
* creating priv/repo/migrations/20170629195946_create_pages.exs
* creating lib/hello/cms.ex
* injecting lib/hello/cms.ex
* creating test/hello/cms/cms_test.exs
* injecting test/hello/cms/cms_test.exs

Add the resource to your CMS :browser scope in lib/hello_web/router.ex:

    scope "/cms", HelloWeb.CMS, as: :cms do
      pipe_through :browser
      ...
      resources "/pages", PageController
    end


Remember to update your repository by running migrations:

    $ mix ecto.migrate

```

ページの `views` 属性はユーザーが直接更新することはないので、生成されたフォームから削除してみましょう。`lib/hello_web/templates/cms/page/form.html.eex`を開き、この部分を削除します。

```eex
-  <%= label f, :views %>
-  <%= number_input f, :views %>
-  <%= error_tag f, :views %>
```

また、`lib/hello/cms/page.ex` を変更して、`:views` を許可されるパラメーターから削除します。

```elixir
  def changeset(%Page{} = page, attrs) do
    page
-    |> cast(attrs, [:title, :body, :views])
-    |> validate_required([:title, :body, :views])
+    |> cast(attrs, [:title, :body])
+    |> validate_required([:title, :body])
  end
```

最後に、`priv/repo/migrations` で新しいファイルを開き、`views` 属性がデフォルト値を持つようにします。

```elixir
    create table(:pages) do
      add :title, :string
      add :body, :text
-     add :views, :integer
+     add :views, :integer, default: 0

      timestamps()
    end
```

今回はジェネレーターに `--web` オプションを渡しました。これは、コントローラーやビューなどのWebモジュールに使用する名前空間をPhoenixに伝えます。これは、既存の `PageController` のようにシステム内でリソースが競合している場合に便利ですし、CMSシステムのように異なる機能のパスや機能を自然に名前空間化することもできます。Phoenixは、`"/cms"`パスプレフィックス用の新しい`scope`をルータに追加するように指示してくれました。以下を `lib/hello_web/router.ex` にコピーペーストしてみましょう（ただし、マクロの `pipe_through` を一箇所変更します）

```
  scope "/cms", HelloWeb.CMS, as: :cms do
    pipe_through [:browser, :authenticate_user]

    resources "/pages", PageController
  end

```

私たちは `:authenticate_user` プラグインを追加して、このCMSのスコープ内のすべてのルートにサインインしたユーザーを要求しました。これで、データベースをマイグレートすることができるようになりました。

```
$ mix ecto.migrate

Compiling 12 files (.ex)
Generated hello app

[info]  == Running Hello.Repo.Migrations.CreatePages.change/0 forward

[info]  create table pages

[info]  == Migrated in 0.0s
```

では、`mix phx.server`でサーバーを起動して、[http://localhost:4000/cms/pages](http://localhost:4000/cms/pages)にアクセスしてみましょう。まだログインしていない場合は、ログインするようにとのメッセージが表示されたホームページにリダイレクトされます。[http://localhost:4000/sessions/new](http://localhost:4000/sessions/new) でログインしてから、[http://localhost:4000/cms/pages](http://localhost:4000/cms/pages) に再アクセスしてみましょう。認証が完了したので、おなじみのページのリソース一覧と `New Page` のリンクが表示されているはずです。

ページを作成する前に、ページ作成者が必要です。`phx.gen.context` ジェネレーターを実行して注入されたコンテキスト関数に加え、`Author`スキーマを生成してみましょう。

```
$ mix phx.gen.context CMS Author authors bio:text role:string \
genre:string user_id:references:users:unique

* creating lib/hello/cms/author.ex
* creating priv/repo/migrations/20170629200937_create_authors.exs
* injecting lib/hello/cms.ex
* injecting test/hello/cms/cms_test.exs

Remember to update your repository by running migrations:

    $ mix ecto.migrate

```

認証のコードを生成したときと同じように、コンテキストジェネレーターを使用してコードを注入しました。著者の経歴、コンテンツ管理システムでの役割、著者が執筆するジャンル、そして最後にアカウントシステムのユーザーへの外部キーのフィールドを追加しました。アカウントのコンテキストは我々のアプリケーションにおけるエンドユーザーの出処であるため、我々はCMSの作者のためにそれに依存することになります。そうは言っても、著者に固有の情報はすべて著者スキーマに残ります。また、仮想フィールドを使用して `Author` をユーザーアカウント情報で装飾し、`User` 構造体を決して公開しないようにすることもできます。これにより、CMS APIの消費者が `User` コンテキストの変更から保護されることが保証されます。

データベースをマイグレートする前に、新しく生成された `*_create_authors.exs` マイグレーションでもう一度データの整合性を処理する必要があります。`priv/repo/migrations` の新しいファイルを開き、外部キー制約に以下の変更を加えます。

```elixir
  def change do
    create table(:authors) do
      add :bio, :text
      add :role, :string
      add :genre, :string
-     add :user_id, references(:users, on_delete: :nothing)
+     add :user_id, references(:users, on_delete: :delete_all),
+                   null: false

      timestamps()
    end

    create unique_index(:authors, [:user_id])
  end
```

データの整合性を確保するために再び `:delete_all` ストラテジーを使用しました。これにより、`Accounts.delete_user/1` を使ってアプリケーションからユーザーが削除されたときに、`Accounts` コンテキスト内のアプリケーションコードに依存して `CMS` の著者レコードのクリーンアップを心配する必要がなくなります。これにより、アプリケーションのコードは切り離され、データの整合性はデータベースの中で行われます。

続ける前に、最終的なマイグレーションを生成する必要があります。著者テーブルができたので、ページと著者を関連付けることができます。ページテーブルに `author_id` フィールドを追加してみましょう。次のコマンドを実行して、新しいマイグレーションを生成します。

```
$ mix ecto.gen.migration add_author_id_to_pages

* creating priv/repo/migrations
* creating priv/repo/migrations/20170629202117_add_author_id_to_pages.exs
```

ここで `priv/repo/migrations` にある新しい `*_add_author_id_to_pages.exs` ファイルを開き、これを入力します。

```elixir
  def change do
    alter table(:pages) do
      add :author_id, references(:authors, on_delete: :delete_all),
                      null: false
    end

    create index(:pages, [:author_id])
  end
```

`alter`マクロを使用して、ページテーブルに著者テーブルへの外部キーである新しい `author_id` フィールドを追加しました。また、`on_delete: :delete_all` オプションを再び使用して、親著者がアプリケーションから削除された際にページを削除します。

では、マイグレートを実行しましょう。

```
$ mix ecto.migrate

[info]  == Running Hello.Repo.Migrations.CreateAuthors.change/0 forward

[info]  create table authors

[info]  create index authors_user_id_index

[info]  == Migrated in 0.0s

[info]  == Running Hello.Repo.Migrations.AddAuthorIdToPages.change/0 forward

[info]  == Migrated in 0.0s
```

データベースの準備ができたので、著者と投稿をCMSシステムに統合してみましょう。

## コンテキスト間のデータ

ソフトウェアの依存関係はしばしば避けられないものですが、可能な限り制限し、依存関係が必要な場合のメンテナンスの負担を軽減するために最善を尽くすことができます。これまでのところ、アプリケーションの2つの主なコンテキストをお互いに分離することに成功しましたが、今度は必要な依存関係を処理しなければなりません。

私たちの `Author` リソースは、CMSの中で著者を表す責任を持ち続けますが、最終的に著者が存在するためには、`Accounts.User` によって表されるエンドユーザーが存在しなければなりません。このことを考えると、私たちの `CMS` コンテキストは `Accounts` コンテキストにデータの依存関係を持つことになります。このことを考慮すると、2つの選択肢があります。1つは `Accounts` コンテキストでAPIを公開し、CMSシステムで使用するためのユーザーデータを効率的に取得できるようにすることです。2つ目はデータベースの結合(join)を使用して従属データを取得することができます。どちらもトレードオフとアプリケーションのサイズを考えると有効なオプションですが、ハードデータの依存関係があるときにデータベースからデータを結合するのは、大規模なクラスのアプリケーションにはちょうど良いでしょう。結合されたコンテキストを後から完全に別のアプリケーションとデータベースに分割することを決めた場合でも、分離の利点を得ることができます。これは、パブリックコンテキストAPIが変更されない可能性が高いからです。

データの依存関係がどこにあるかわかったので、スキーマの関連付けを追加して、ページと作者、作者とユーザーを結びつけることができるようにしましょう。以下の変更を `lib/hello/cms/page.ex` に行います。

```elixir
+ alias Hello.CMS.Author


  schema "pages" do
    field :body, :string
    field :title, :string
    field :views, :integer
+   belongs_to :author, Author

    timestamps()
  end
```

ページと著者の間に `belongs_to` の関係を追加しました。
次に、`lib/hello/cms/author.ex`に逆方向の関連付けを追加してみましょう。

```elixir

+ alias Hello.CMS.Page


  schema "authors" do
    field :bio, :string
    field :genre, :string
    field :role, :string

-   field :user_id, :id
+   has_many :pages, Page
+   belongs_to :user, Hello.Accounts.User

    timestamps()
  end
```

作者のページへ `has_many` アソシエーションを追加しました。そして、`belongs_to` アソシエーションを `Accounts.User` スキーマに繋げることで、`Accounts` コンテキストへのデータ依存性を導入しました。

アソシエーションが整ったので、ページの作成や更新の際に作者を要求するように `CMS` コンテキストを更新してみましょう。まずはデータ取得の変更から始めましょう。`lib/hello/cms.ex` で `CMS` コンテキストを開き、`list_pages/0`, `get_page!/1`, `get_author!/1` 関数を以下の定義に置き換えます。


```elixir
  alias Hello.CMS.{Page, Author}
  alias Hello.Accounts

  def list_pages do
    Page
    |> Repo.all()
    |> Repo.preload(author: [user: :credential])
  end

  def get_page!(id) do
    Page
    |> Repo.get!(id)
    |> Repo.preload(author: [user: :credential])
  end

  def get_author!(id) do
    Author
    |> Repo.get!(id)
    |> Repo.preload(user: :credential)
  end
```

まず、`list_pages/0` 関数を書き換えて、関連する著者、ユーザー、クレデンシャルデータをデータベースからプリロードするようにしました。次に、必要なデータをプリロードするために `get_page!/1` と `get_author!/1` を書き換えました。

データアクセス関数ができたので、次は永続性に焦点を当ててみましょう。ページと並行して著者を取得することはできますが、ページを作成したり編集したりする際に著者を永続化することはできません。これを修正しましょう。`lib/hello/cms.ex` を開いて、以下の変更を行ってください。


```elixir
def create_page(%Author{} = author, attrs \\ %{}) do
  %Page{}
  |> Page.changeset(attrs)
  |> Ecto.Changeset.put_change(:author_id, author.id)
  |> Repo.insert()
end

def ensure_author_exists(%Accounts.User{} = user) do
  %Author{user_id: user.id}
  |> Ecto.Changeset.change()
  |> Ecto.Changeset.unique_constraint(:user_id)
  |> Repo.insert()
  |> handle_existing_author()
end
defp handle_existing_author({:ok, author}), do: author
defp handle_existing_author({:error, changeset}) do
  Repo.get_by!(Author, user_id: changeset.data.user_id)
end
```

ちょっとしたコードがあるので、分解してみましょう。まず、`create_page` 関数を書き直して、記事を公開した著者を意味する `CMS.Author` 構造体を必要とするようにしました。次に、チェンジセットを取得して `Ecto.Changeset.put_change/2` に渡し、`author_id` の関連付けをチェンジセットに配置します。次に、`Repo.insert` を使ってデータベースに関連づけられた`author_id`を含む新しいページを挿入します。

私たちのCMSシステムでは、エンドユーザーが投稿を公開する前に著者が存在している必要があるので、プログラムで著者を作成できるように `ensure_author_exists` 関数を追加しました。この新しい関数は `Accounts.User` 構造体を受け取り、その `user.id` を持つアプリケーション内の既存の著者を見つけるか、そのユーザーのために新しい著者を作成します。作成者テーブルの外部キー `user_id` には一意の制約があるので、重複した作成者を許容する競合状態から保護されています。そうは言っても、別のユーザーが挿入された場合に競合状態にならないようにする必要があります。これを達成するために、`Ecto.Changeset.change/1` を使用して専用のチェンジセットを作成し、新しい `Author` 構造体の `user_id` を受け入れます。チェンジセットの唯一の目的は、一意の制約違反を処理可能なエラーに変換することです。新しい著者を `Repo.insert/1` で挿入しようとした後、成功と失敗のケースにマッチする `handle_existing_author/1` にパイプします。成功した場合はこれで完了で、作成された著者を返すだけです。そうでない場合は `Repo.get_by!` を用いて、すでに存在する `user_id` の著者を取得します。

これで `CMS` の変更は終わりです。それでは、追加した内容をサポートするためにウェブレイヤーを更新していきましょう。個々のCMSコントローラーアクションを更新する前に、`CMS.PageController` プラグパイプラインにいくつかの追加を行う必要があります。まず、CMSにアクセスするエンドユーザーのために著者が存在することを確認し、ページオーナーへのアクセスを許可する必要があります。

生成した `lib/hello_web/controllers/cms/page_controller.ex` を開き、以下の追加を行います。

```elixir

  plug :require_existing_author
  plug :authorize_page when action in [:edit, :update, :delete]

  ...

  defp require_existing_author(conn, _) do
    author = CMS.ensure_author_exists(conn.assigns.current_user)
    assign(conn, :current_author, author)
  end

  defp authorize_page(conn, _) do
    page = CMS.get_page!(conn.params["id"])

    if conn.assigns.current_author.id == page.author_id do
      assign(conn, :page, page)
    else
      conn
      |> put_flash(:error, "You can't modify that page")
      |> redirect(to: Routes.cms_page_path(conn, :index))
      |> halt()
    end
  end
```

`CMS.PageController`に2つのプラグを追加しました。最初のプラグ `:require_existing_author` は、このコントローラーのすべてのアクションに対して実行されます。`require_existing_author/2` プラグは `CMS.ensure_author_exists/1` を呼び出し、コネクションのassignから `current_user` を渡します。作者を見つけたり作成したりした後、`Plug.Conn.assign/3` を使って `:current_author` のキーをアサインし、後続の処理で使用するためにアサインします。

次に、`:authorize_page` プラグを追加しました。これはプラグのガード句の機能を利用したもので、プラグを特定のアクションのみに制限できます。`authorize_page/2` プラグの定義では、まずコネクションのパラメーターからページを取得し、次に `current_author` に対して認証チェックを行います。現在の著者のIDが取得したページのIDと一致すれば、ページの所有者がページにアクセスしていることが確認され、コントローラーのアクションで利用される`page`をコネクションのassignに割り当てます。認証に失敗した場合は、フラッシュエラーメッセージを追加し、ページインデックス画面にリダイレクトしてから `Plug.Conn.halt/1` を呼び出し、プラグパイプラインが継続してコントローラーアクションを呼び出すのを防ぎます。

新しいプラグを導入したことで、`create`, `edit`, `update`, `delete` の各アクションを変更して、コネクションアサインの新しい値を利用できるようになりました。

```elixir
- def edit(conn, %{"id" => id}) do
+ def edit(conn, _) do
-   page = CMS.get_page!(id)
-   changeset = CMS.change_page(page)
+   changeset = CMS.change_page(conn.assigns.page)
-   render(conn, "edit.html", page: page, changeset: changeset)
+   render(conn, "edit.html", changeset: changeset)
  end

  def create(conn, %{"page" => page_params}) do
-   case CMS.create_page(page_params) do
+   case CMS.create_page(conn.assigns.current_author, page_params) do
      {:ok, page} ->
        conn
        |> put_flash(:info, "Page created successfully.")
        |> redirect(to: Routes.cms_page_path(conn, :show, page))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

- def update(conn, %{"id" => id, "page" => page_params}) do
+ def update(conn, %{"page" => page_params}) do
-   page = CMS.get_page!(id)
-   case CMS.update_page(page, page_params) do
+   case CMS.update_page(conn.assigns.page, page_params) do
      {:ok, page} ->
        conn
        |> put_flash(:info, "Page updated successfully.")
        |> redirect(to: Routes.cms_page_path(conn, :show, page))
      {:error, %Ecto.Changeset{} = changeset} ->
-       render(conn, "edit.html", page: page, changeset: changeset)
+       render(conn, "edit.html", changeset: changeset)
    end
  end

- def delete(conn, %{"id" => id}) do
+ def delete(conn, _) do
-   page = CMS.get_page!(id)
-   {:ok, _page} = CMS.delete_page(page)
+   {:ok, _page} = CMS.delete_page(conn.assigns.page)

    conn
    |> put_flash(:info, "Page deleted successfully.")
    |> redirect(to: Routes.cms_page_path(conn, :index))
  end
```

`create`アクションを変更して、`require_existing_author` プラグインで指定したコネクションのassignから `current_author` を取得するようにしました。次に現在の著者を `CMS.create_page` に渡し、新しいページに著者を関連付けるために使用しています。次に、`update` アクションを変更して直接取得するのではなく、`conn.assigns.page` を`CMS.update_page/2` へ渡すようにしました。`authorize_page` プラグインはすでにページを取得してassignに設定しているので、アクションの中で単純に参照できます。同様に、`delete` アクションを更新して `conn.assigns.page` を `CMS` へ渡すようにしました。

ウェブの変更を完了させるために、ページを表示する際に作者を表示させてみましょう。まず、`lib/hello_web/views/cms/page_view.ex`を開き、著者名の書式設定を扱うヘルパー関数を追加します。

```elixir
defmodule HelloWeb.CMS.PageView do
  use HelloWeb, :view

  alias Hello.CMS

  def author_name(%CMS.Page{author: author}) do
    author.user.name
  end
end
```

次に、`lib/hello_web/templates/cms/page/show.html.eex`を開き、新しい関数を利用してみましょう。

```diff
+ <li>
+   <strong>Author:</strong>
+   <%= author_name(@page) %>
+ </li>
</ul>
```

それでは、`mix phx.server`でサーバーを起動して試してみましょう。[http://localhost:4000/cms/pages/new](http://localhost:4000/cms/pages/new)にアクセスして、新しいページを保存してください。

```
Page created successfully.

Show Page Title: Home
Body: Welcome to Phoenix!
Views: 0
Author: Chris
```

そして、それは機能します!。今では、ユーザーアカウントとコンテンツ管理を担当する2つの分離されたコンテキストを持っています。コンテンツ管理システムを必要に応じてアカウントに結合し、それぞれのシステムを可能な限り分離しています。これにより、アプリケーションを成長させるための素晴らしい基盤ができました。

## CMSの関数を追加する

アカウントのコンテキストを `Accounts.authenticate_by_email_password/2` のようなアプリケーション固有の関数で拡張したように、生成された `CMS` のコンテキストを新しい機能で拡張してみましょう。どんなCMSシステムにとっても、ページが何回閲覧されたかを追跡する機能は人気ランキングのために不可欠です。既存の `CMS.update_page` 関数を使って `CMS.update_page(user, page, %{views: page.views + 1})` のようにすることもできますが、これは競合が発生しやすいだけでなく、呼び出し元がCMSシステムについて知りすぎる必要があります。競合がなぜ存在するのかを確認するために、起こりうるイベントの実行例を見てみましょう。

直感的には、次のような出来事を想定しているはずです。

  1. ユーザー1は、13のカウントでページをロードします
  2. ユーザー1は、14のカウントでページを保存します。
  3. ユーザー2は、14のカウントでページをロードします
  4. ユーザー2は、15のカウントでページをロードします

実際にはこうなるでしょう。

  1. ユーザー1、は13のカウントでページをロードします
  2. ユーザー2、は13のカウントでページをロードします
  3. ユーザー1は、14のカウントでページを保存します。
  4. ユーザー2は、14のカウントでページを保存します。

競合条件によって複数の呼び出し元が日付の切れたビュー値を更新している可能性があるため、既存のテーブルを更新するには信頼性の低い方法になってしまいます。もっと良い方法があります。

ここでも、何を達成したいかを表す関数名を考えてみましょう。

    > page = CMS.inc_page_views(page)

これは素晴らしいですね。呼び出し側はこの関数が何をするのか混乱することはありませんし、競合状態を防ぐためにインクリメントをアトミックな操作でまとめることができます。

CMSコンテキスト（`lib/hello/cms.ex`）を開き、この新しい関数を追加します。


```elixir
def inc_page_views(%Page{} = page) do
  {1, [%Page{views: views}]} =
    from(p in Page, where: p.id == ^page.id, select: [:views])
    |> Repo.update_all(inc: [views: 1])

  put_in(page.views, views)
end
```

現在のページのIDを指定して `Repo.update_all` に渡すクエリを作成しました。Ectoの `Repo.update_all` はデータベースに対してバッチ更新を行うことができ、ビュー数の増加などの値をアトミックに更新するのに最適です。レポ操作の結果は更新されたレコードの数と `select` オプションで指定したスキーマの値を返します。新しいページビューを受け取ったら、`put_in(page.views, views)` を使ってページ内に新しいビュー数を配置します。

コンテキスト関数を用意したので、CMSのページコントローラーで利用してみましょう。新しい関数を呼び出すために `lib/hello_web/controllers/cms/page_controller.ex` の `show` アクションを更新してください。

```elixir
def show(conn, %{"id" => id}) do
  page =
    id
    |> CMS.get_page!()
    |> CMS.inc_page_views()

  render(conn, "show.html", page: page)
end
```

`show`アクションを変更して、取得したページを `CMS.inc_page_views/1` にパイプし、更新されたページを返すようにしました。そして、以前と同じようにテンプレートをレンダリングしました。それでは試してみましょう。何度かページをリフレッシュして、ビュー数が増えていくのを見てください。

また、アトミックアップデートの動作をectoのデバッグログで見ることができます。

```
[debug] QUERY OK source="pages" db=3.1ms
UPDATE "pages" AS p0 SET "views" = p0."views" + $1 WHERE (p0."id" = $2)
RETURNING p0."views" [1, 3]
```

お疲れ様でした。

これまで見てきたように、コンテキストを使って設計することで、アプリケーションを成長させるための強固な基盤が得られます。システムの意図を公開する個別の、よく定義されたAPIを使用することで、再利用可能なコードでより保守性の高いアプリケーションを書くことができます。

## FAQ

### コンテキストAPIからEcto構造体を返す

コンテキストAPIを探っていくうちに、疑問に思ったことがあるかもしれません。

> コンテキストの目的の1つがEctoレポアクセスをカプセル化することだとしたら、ユーザーの作成に失敗したときに `create_user/1` が `Ecto.Changeset` 構造体を返すのはなぜでしょうか?

答えは、`%Ecto.Changeset{}` をアプリケーションのパブリックな *data-structure* として公開することにしたことです。以前、チェンジセットによってフィールドの変更を追跡し、バリデーションを行い、エラーメッセージを生成することができることを見ました。ここでの使用は、プライベートのレポアクセスやEcto changeset API内部から切り離されています。呼び出し元が理解できるデータ構造を公開しており、フィールドエラーのような豊富な情報を含んでいます。便利なことに、`phoenix_ecto` プロジェクトは必要な `Phoenix.Param` と [`Phoenix.HTML.FormData`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.FormData.html) プロトコルを実装しており、フォーム生成やエラーメッセージなどのために `%Ecto.Changeset{}` をどのように扱うかを知っています。また、同じ目的のために `%Accounts.Changes{}` 構造体を定義し、ウェブ層の統合のためにPhoenixプロトコルを実装したと考えることもできます。

### クロスコンテキストワークフローの戦略

私たちのCMSコンテキストは、ユーザーがページコンテンツを公開することを決定したときに、システム内で著者を作成することをサポートしています。システムのすべてのユーザーがCMSの作者になるわけではないので、このユースケースは理にかなっています。しかし、アプリのすべてのユーザーが本当に著者である場合はどうでしょうか？

`Accounts.User`が作成されるたびに `CMS.Author` が存在する必要がある場合、この依存関係をどこに置くかを注意深く考えなければなりません。私たちの `CMS` コンテキストが `Accounts` コンテキストに依存していることはわかっていますが、コンテキスト間の循環的な依存関係を避けることが重要です。たとえば、`Accounts.create_user` 関数を次のように変更したとします。


```elixir
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Ecto.Changeset.cast_assoc(:credential, with: &Credential.changeset/2)
  |> Ecto.Changeset.put_assoc(:author, %Author{...})
  |> Repo.insert()
end
```

これで目的は達成されるかもしれませんが、`Accounts` コンテキストのスキーマ関係を `CMS` の著者につなぐ必要があります。さらに悪いことに、孤立した `Accounts` コンテキストを利用して、コンテンツ管理システムについて知ることを要求しています。これは、アプリケーション内で孤立した責任を持たせるのと異なります。これらの要件を処理するもっと良い方法があります。

もし、同じような状況で、ユースケースがコンテキスト間で循環する依存関係を作成する必要があると感じたら、それはアプリケーションの要件を処理するためにシステム内で新しいコンテキストが必要であることを示しています。本当に必要なのは、ユーザーが作成されたり、アプリケーションに登録されたりしたときに、すべての要件を処理するインターフェイスです。これを処理するために、`UserRegistration` コンテキストを作成し、`Accounts` と `CMS` APIの両方を呼び出してユーザーを作成し、CMSの著者を関連付けます。これにより、Accountsを可能な限り分離できるだけでなく、システム内の `UserRegistration` の必要性を処理するための明快で明白なAPIが得られます。このアプローチを採用すれば、`Ecto.Multi` のようなツールを使用して、内部のデータベース呼び出しを深くカップリングすることなく、異なるコンテキスト操作にまたがってトランザクションを処理することもできます。`UserRegistration`のAPIの一部は以下のようになります。

```elixir
defmodule Hello.UserRegistration do
  alias Ecto.Multi
  alias Hello.{Accounts, CMS}

  def register_user(params) do
    Multi.new()
    |> Multi.run(:user, fn _repo, _ -> Accounts.create_user(params) end)
    |> Multi.run(:author, fn_repo, %{user: user} ->
      {:ok, CMS.ensure_author_exists(user)}
    end)
    |> Repo.transaction()
  end
end
```

`Ecto.Multi` を利用して `Repo` のトランザクション内で実行できる処理のパイプラインを作成できます。指定した処理に失敗した場合、トランザクションはロールバックされ、どの操作に失敗したかとそれまでの変更内容を含むエラーが返されます。`register_user/1`の例では2つの処理を指定し、1つは `Accounts.create_user/1` を呼び出す処理で、もう1つは新しく作成されたユーザーを `CMS.ensure_author_exists/1` に渡す操作です。この関数の最後のステップは `Repo.transaction/1` で処理を呼び出すことです。

`UserRegistration`の導入は、私たちが構築した動的なAuthorシステムよりも実装が簡単でしょう。私たちは、より困難な道を選ぶことにしました。それはまさに、開発者が毎日アプリケーションに対して下す決断だからです。
