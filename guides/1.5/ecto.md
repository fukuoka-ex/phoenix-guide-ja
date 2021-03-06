---
layout: 1.5/layout
version: 1.5
group: guides
title: Ecto
nav_order: 7
hash: 5f654692
---
# Ecto

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

今日のほとんどのWebアプリケーションでは、何らかの形でのデータのバリデーションと永続化が必要です。Elixirのエコシステムでは、これを可能にするEctoがあります。データベースをもったWeb機能を構築する前に、Ectoの詳細に焦点を当てて、Web機能を構築するための強固な基盤となるようにします。さあ、始めましょう!

PhoenixはEctoを使用して、以下のデータベースをサポートしています。

* PostgreSQL (via [`postgrex`](https://github.com/elixir-ecto/postgrex))
* MySQL (via [`myxql`](https://github.com/elixir-ecto/myxql))
* MSSQL (via [`tds`](https://github.com/livehelpnow/tds))

新しく生成されたPhoenixプロジェクトには、デフォルトでPostgreSQLアダプターのEctoが含まれています。`--database` オプションを使用して変更するか、`--no-ecto` を使用して除外できます。

Ectoは他のデータベースのサポートも提供しており、多くの学習用リソースも用意されています。一般的な情報は[EctoのREADME](https://github.com/elixir-ecto/ecto)をご覧ください。

このガイドでは、Ecto統合で新しいアプリケーションを生成し、PostgreSQLを使用することを前提としています。入門ガイドでは、最初のアプリケーションを起動して実行する方法を説明しています。MySQLへの切り替え方法については、[MySQLの使用](#using-mysql)の項を参照してください。

## スキーマとマイグレーションジェネレーターを使用する

EctoとPostgresのインストールと設定が完了したので、Ectoを使用するもっとも簡単な方法は、`phx.gen.schema` タスクを使ってEcto *スキーマ* を生成することです。Ectoスキーマは、Elixirのデータ型がデータベーステーブルなどの外部ソースとどのようにマッピングするかを指定するためのものです。ここでは、`name`、 `email`、 `bio`、 `number_of_pets` フィールドを持つ `User` スキーマを生成してみましょう。

```console
$ mix phx.gen.schema User users name:string email:string \
bio:string number_of_pets:integer

* creating ./lib/hello/user.ex
* creating priv/repo/migrations/20170523151118_create_users.exs

Remember to update your repository by running migrations:

   $ mix ecto.migrate
```

このタスクではいくつかのファイルが生成されました。まず、`user.ex` ファイルがあり、タスクに渡したフィールドのスキーマ定義を含むEctoスキーマが含まれています。次に、`priv/repo/migrations` の中にマイグレーションファイルが生成され、スキーマがマップされるデータベーステーブルが作成されます。

ファイルを用意したので、指示にしたがってマイグレーションを実行してみましょう。

```console
$ mix ecto.migrate
Compiling 1 file (.ex)
Generated hello app

[info]  == Running Hello.Repo.Migrations.CreateUsers.change/0 forward

[info]  create table users

[info]  == Migrated in 0.0s
```

Mixは、`MIX_ENV=prod mix ecto.migrate` で指定しない限り、development環境であるとみなします。

データベースサーバにログインして `hello_dev` データベースに接続すると、`users` テーブルが表示されるはずです。Ectoは主キーとして `id` という整数型のカラムが必要だと想定しているので、そのために生成されたシーケンスが表示されるはずです。

```console
$ psql -U postgres

Type "help" for help.

postgres=# \connect hello_dev
You are now connected to database "hello_dev" as user "postgres".
hello_dev=# \d
                List of relations
 Schema |       Name        |   Type   |  Owner
--------+-------------------+----------+----------
 public | schema_migrations | table    | postgres
 public | users             | table    | postgres
 public | users_id_seq      | sequence | postgres
(3 rows)
hello_dev=# \q
```

`priv/repo/migrations` にある `phx.gen.schema` が生成したマイグレーションを見てみると、指定したカラムが追加されていることがわかります。また、`timestamps/0` 関数を呼び出すことで `inserted_at` と `updated_at` のタイムスタンプカラムも追加されます。

```elixir
defmodule Hello.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :bio, :string
      add :number_of_pets, :integer

      timestamps()
    end

  end
end
```

そして、実際の `users` テーブルでは次のように変換されます。

```console
hello_dev=# \d users
Table "public.users"
Column         |            Type             | Modifiers
---------------+-----------------------------+----------------------------------------------------
id             | integer                     | not null default nextval('users_id_seq'::regclass)
name           | character varying(255)      |
email          | character varying(255)      |
bio            | character varying(255)      |
number_of_pets | integer                     |
inserted_at    | timestamp without time zone | not null
updated_at     | timestamp without time zone | not null
Indexes:
"users_pkey" PRIMARY KEY, btree (id)
```

マイグレーションではフィールドとしてリストアップされていませんが、デフォルトでは `id` カラムが主キーとして取得されていることに注意してください。

## Repoの設定

`Hello.Repo` モジュールは、Phoenixアプリケーションでデータベースを扱うために必要な基盤です。Phoenixはこれを `lib/hello/repo.ex` で生成してくれました。次に抜粋します。

```elixir
defmodule Hello.Repo do
  use Ecto.Repo,
    otp_app: :hello,
    adapter: Ecto.Adapters.Postgres
end
```

これは、まず `otp_app` 名とRe@opモジュールを設定します。次にアダプター - 今回の場合はPostgresを設定しています。また、ログイン認証情報も設定します。もちろん、実際の認証情報と異なる場合は、これらを変更できます。

私たちのRepoには3つの主要なタスクがあります。それは `Ecto.Repo` から共通のクエリ関数をすべて取り込むこと、`otp_app` の名前をアプリケーション名と同じに設定すること、そしてデータベースアダプターを設定することです。Repoの使い方については、もう少し詳しく説明します。

`phx.new` でアプリケーションを生成したときには、基本的なRepoの設定も含まれていました。`config/dev.exs` を見てみましょう。

```elixir
...
# Configure your database
config :hello, Hello.Repo,
  username: "postgres",
  password: "postgres",
  database: "hello_dev",
  hostname: "localhost",
  pool_size: 10
...
```

また、`config/test.exs` と `config/prod.secret.exs` にも同様の設定がありますが、これも実際の認証情報に合わせて変更できます。

## スキーマ

Ectoスキーマは、Elixirの値を外部データソースにマッピングしたり、外部データをElixirのデータ構造にマッピングしたりします。また、アプリケーション内の他のスキーマとの関係を定義することもできます。たとえば、`User` スキーマには多くの `Post` があり、それぞれの `Post` は `User` に属しているかもしれません。Ectoはチェンジセットを使ったデータのバリデーションや型キャストも処理します。後ほど説明をします。

これはPhoenixが生成してくれた `User` スキーマです。

```elixir
defmodule Hello.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hello.User


  schema "users" do
    field :bio, :string
    field :email, :string
    field :name, :string
    field :number_of_pets, :integer

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio, :number_of_pets])
  end
end
```

Ectoスキーマのコアとなるのは、単純にElixirの構造体です。私たちの `schema` ブロックは、外部の `users` テーブルとの間で `%User{}` 構造体フィールドをどのようにキャストするかをEctoに伝えるものです。多くの場合、データベースとの間で単にデータをキャストするだけでは十分ではなく、追加のデータバリデーションが必要になります。そこでEctoチェンジセットの出番です。さあ、飛び込んでみましょう。

## チェンジセットとバリデーション

チェンジセットは、アプリケーションで使用する前に必要なデータ変換のパイプラインを定義します。これらの変換には、型キャスト、ユーザー入力のバリデーション、余計なパラメーターのフィルタリングなどが含まれます。多くの場合、データベースへ書き込む前にユーザー入力をバリデーションするためにチェンジセットを使用します。Ecto Repoもチェンジセットに対応していて、これは無効なデータを拒否するだけでなく、どのフィールドが変更されたかを知るためにチェンジセットを検査することで、可能な限り最小限のデータベース更新を実行することを可能にします。

デフォルトのチェンジセット関数を詳しく見てみましょう。

```elixir
def changeset(%User{} = user, attrs) do
  user
  |> cast(attrs, [:name, :email, :bio, :number_of_pets])
  |> validate_required([:name, :email, :bio, :number_of_pets])
end
```

今、パイプラインには2つの変換があります。最初の呼び出しでは、[`Ecto.Changeset.cast/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/3) を呼び出し、外部パラメーターを渡し、バリデーションに必要なフィールドをマークします。

`cast/3` は最初に構造体を受け取り、次にパラメーター（提案されている更新）を受け取り、最後のフィールドは更新されるカラムのリストです。また、`cast/3` はスキーマに存在するフィールドのみを取ります。

次に [`validate_required/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3) は、`cast/3` が返すチェンジセットにこのフィールドのリストが存在するかどうかをチェックします。ジェネレーターのデフォルトでは、すべてのフィールドが必須となっています。

この機能はiexで検証できます。それでは、`iex -S mix` を実行して `iex` 内でアプリケーションを起動してみましょう。タイプを最小限にして読みやすくするために、`Hello.User` 構造体をエイリアスにしてみましょう。

```console
$ iex -S mix

iex> alias Hello.User
Hello.User
```

次に、空の `User` 構造体と空のパラメーターマップを使ってスキーマからチェンジセットを構築してみましょう。

```elixir
iex> changeset = User.changeset(%User{}, %{})

#Ecto.Changeset<action: nil, changes: %{},
 errors: [name: {"can't be blank", [validation: :required]},
  email: {"can't be blank", [validation: :required]},
  bio: {"can't be blank", [validation: :required]},
  number_of_pets: {"can't be blank", [validation: :required]}],
 data: #Hello.User<>, valid?: false>
```

チェンジセットがあれば、それが有効かどうかをチェックできます。

```elixir
iex> changeset.valid?
false
```

このチェンジセットは有効ではないので、エラーが何であるかを確認できます。

```elixir
iex> changeset.errors
[name: {"can't be blank", [validation: :required]},
 email: {"can't be blank", [validation: :required]},
 bio: {"can't be blank", [validation: :required]},
 number_of_pets: {"can't be blank", [validation: :required]}]
```

では、`number_of_pets` を任意にしてみましょう。これを行うには、単にリストから削除するだけです。

```elixir
    |> validate_required([:name, :email, :bio])
```

さて、チェンジセットをキャストすると、`name`, `email`, `bio` だけが空白にできないことがわかるはずです。これをテストするには、`iex` の中で `recompile()` を実行し、チェンジセットを再構築します。

```elixir
iex> recompile()
Compiling 1 file (.ex)
:ok

iex> changeset = User.changeset(%User{}, %{})
#Ecto.Changeset<action: nil, changes: %{},
 errors: [name: {"can't be blank", [validation: :required]},
  email: {"can't be blank", [validation: :required]},
  bio: {"can't be blank", [validation: :required]}],
 data: #Hello.User<>, valid?: false>

iex> changeset.errors
[name: {"can't be blank", [validation: :required]},
 email: {"can't be blank", [validation: :required]},
 bio: {"can't be blank", [validation: :required]}]
```

スキーマで定義されていない、または必須ではないキーと値のペアを渡すとどうなるでしょうか？

起動中のIExシェル内で、有効な値に加えて `random_key: "random value"` を含む `params` マップを作成してみましょう。

```elixir
iex> params = %{name: "Joe Example", email: "joe@example.com", bio: "An example to all", number_of_pets: 5, random_key: "random value"}
%{email: "joe@example.com", name: "Joe Example", bio: "An example to all",
number_of_pets: 5, random_key: "random value"}
```

次に、新しい `params` マップを使って別のチェンジセットを作成してみましょう。

```elixir
iex> changeset = User.changeset(%User{}, params)
#Ecto.Changeset<action: nil,
 changes: %{bio: "An example to all", email: "joe@example.com",
   name: "Joe Example", number_of_pets: 5}, errors: [],
 data: #Hello.User<>, valid?: true>
```

新しいチェンジセットは有効です。

```elixir
iex> changeset.valid?
true
```

また、チェンジセットの変更点、つまりすべての変換が完了した後に得られるマップをチェックすることもできます。

```elixir
iex(9)> changeset.changes
%{bio: "An example to all", email: "joe@example.com", name: "Joe Example",
  number_of_pets: 5}
```

最終的なチェンジセットから `random_key` と `random_value` が削除されていることに注目してください。チェンジセットを使うと、Webフォームのユーザー入力やCSVファイルからのデータなどの外部データを有効なデータとしてシステムにキャストできます。無効なパラメーターは削除され、スキーマにしたがってキャストできない不正なデータはチェンジセットエラーで強調されます。

バリデーション可能なことはフィールドが必須かどうかだけではありません。より詳細なバリデーションを見てみましょう。

システム内のすべての自己紹介は少なくとも2文字以上の長さでなければならないという要件があったとしたらどうでしょうか？これは、チェンジセットのパイプラインに別の変換を追加して、`bio` フィールドの長さをバリデーションすることで簡単に行うことができます。

```elixir
def changeset(%User{} = user, attrs) do
  user
  |> cast(attrs, [:name, :email, :bio, :number_of_pets])
  |> validate_required([:name, :email, :bio, :number_of_pets])
  |> validate_length(:bio, min: 2)
end
```

さて、ユーザーの経歴に "A" の値を含むデータをキャストしようとすると、チェンジセットのエラーにバリデーションの失敗が表示されるはずです。


```elixir
iex> changeset = User.changeset(%User{}, %{bio: "A"})
iex> changeset.errors[:bio]
{"should be at least %{count} character(s)",
 [count: 2, validation: :length, min: 2]}
```

経歴が保存できる最大の長さの要件もあれば、別のバリデーションを追加すればいいだけです。

```elixir
def changeset(%User{} = user, attrs) do
  user
  |> cast(attrs, [:name, :email, :bio, :number_of_pets])
  |> validate_required([:name, :email, :bio, :number_of_pets])
  |> validate_length(:bio, min: 2)
  |> validate_length(:bio, max: 140)
end
```

ここでは、`email` フィールドに対して、少なくともいくつかの初歩的なフォーマットのバリデーションを行いたいとします。チェックしたいのは"@"の存在だけです。関数 `validate_format/3` はまさにぴったりです。

```elixir
def changeset(%User{} = user, attrs) do
  user
  |> cast(attrs, [:name, :email, :bio, :number_of_pets])
  |> validate_required([:name, :email, :bio, :number_of_pets])
  |> validate_length(:bio, min: 2)
  |> validate_length(:bio, max: 140)
  |> validate_format(:email, ~r/@/)
end
```

"example.com"というメールアドレスでユーザーをキャストしようとすると、以下のようなエラーメッセージが表示されるはずです。

```elixir
iex> changeset = User.changeset(%User{}, %{email: "example.com"})
iex> changeset.errors[:email]
{"has invalid format", [validation: :format]}
```

チェンジセットで実行できるバリデーションや変換は他にもたくさんあります。詳細は [Ecto Changesetのドキュメント](https://hexdocs.pm/ecto/Ecto.Changeset.html) を参照してください。

## データ永続化

マイグレーションとスキーマを検討しましたが、スキーマやチェンジセットはまだ永続化していません。以前に `lib/hello/repo.ex` にあるrepoモジュールを簡単に見てみましたが、それを使うときがきました。

Ecto Reposは、PostgreSQLのようなデータベースであっても、RESTful APIのような外部サービスであっても、ストレージシステムへのインターフェイズです。Repoモジュールの目的は、永続化とデータの問い合わせの詳細を処理することです。呼び出し側としては、データの取得と永続化だけを気にします。Repoは、基礎となるデータベースアダプター通信、コネクションプーリング、データベース制約違反のためのエラー変換を行います。

それでは、`iex -S mix` を使ってIExに戻り、データベースにユーザーを数人挿入してみましょう。

```elixir
iex> alias Hello.{Repo, User}
[Hello.Repo, Hello.User]

iex> Repo.insert(%User{email: "user1@example.com"})
[debug] QUERY OK db=4.6ms
{% raw %}INSERT INTO "users" ("email","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["user1@example.com", {{2017, 5, 23}, {19, 6, 4, 822044}}, {{2017, 5, 23}, {19, 6, 4, 822055}}]{% endraw %}
{:ok,
 %Hello.User{__meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  bio: nil, email: "user1@example.com", id: 3,
  inserted_at: ~N[2017-05-23 19:06:04.822044], name: nil, number_of_pets: nil,
  updated_at: ~N[2017-05-23 19:06:04.822055]}}

iex> Repo.insert(%User{email: "user2@example.com"})
[debug] QUERY OK db=5.1ms
{% raw %}INSERT INTO "users" ("email","inserted_at","updated_at") VALUES ($1,$2,$3) RETURNING "id" ["user2@example.com", {{2017, 5, 23}, {19, 6, 8, 452545}}, {{2017, 5, 23}, {19, 6, 8, 452556}}]{% endraw %}
{:ok,
 %Hello.User{__meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  bio: nil, email: "user2@example.com", id: 4,
  inserted_at: ~N[2017-05-23 19:06:08.452545], name: nil, number_of_pets: nil,
  updated_at: ~N[2017-05-23 19:06:08.452556]}}
```

アクセスしやすいように `User` と `Repo` モジュールにエイリアスを付けることから始めました。次に `Repo.insert/1` を呼び出し、ユーザー構造体を渡しました。ここは `dev` 環境なので、基礎となる `%User{}` データを挿入する際にRepoが実行したクエリのデバッグログを見ることができます。`{:ok, %User{}}` を含む2要素のタプルが返ってきていて、これは挿入が成功したことを示しています。いくつかのユーザーが挿入されたので、Repoからそれらのユーザーを取得してみましょう。

```elixir
iex> Repo.all(User)
[debug] QUERY OK source="users" db=2.7ms
SELECT u0."id", u0."bio", u0."email", u0."name", u0."number_of_pets", u0."inserted_at", u0."updated_at" FROM "users" AS u0 []
[%Hello.User{__meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  bio: nil, email: "user1@example.com", id: 3,
  inserted_at: ~N[2017-05-23 19:06:04.822044], name: nil, number_of_pets: nil,
  updated_at: ~N[2017-05-23 19:06:04.822055]},
 %Hello.User{__meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  bio: nil, email: "user2@example.com", id: 4,
  inserted_at: ~N[2017-05-23 19:06:08.452545], name: nil, number_of_pets: nil,
  updated_at: ~N[2017-05-23 19:06:08.452556]}]
```

簡単でしたね! `Repo.all/1` はデータソース、この場合は `User` スキーマを受け取り、それをデータベースに対する基礎となるSQLクエリーに変換します。データを取得した後、RepoはEctoスキーマを使用してデータベースの値を `User` スキーマにしたがってElixirのデータ構造にマッピングします。Ectoには、基本的なクエリーだけではなく、高度なSQL生成のための本格的なクエリーDSLが含まれています。自然なElixir DSLに加えて、Ectoのクエリーエンジンは、SQLインジェクションの保護やクエリーのコンパイル時の最適化など、複数の優れた機能を提供してくれます。早速試してみましょう。

```elixir
iex> import Ecto.Query
Ecto.Query

iex> Repo.all(from u in User, select: u.email)
[debug] QUERY OK source="users" db=2.4ms
SELECT u0."email" FROM "users" AS u0 []
["user1@example.com", "user2@example.com"]
```

まず、EctoのクエリーDSLの `from` マクロをインポートするように `Ecto.Query` をインポートしました。次に、ユーザーテーブルにあるすべてのメールアドレスを選択するクエリーを作成しました。別の例を試してみましょう。

```elixir
iex)> Repo.one(from u in User, where: ilike(u.email, "%1%"),
                               select: count(u.id))
[debug] QUERY OK source="users" db=1.6ms SELECT count(u0."id") FROM "users" AS u0 WHERE (u0."email" ILIKE '%1%') []
1
```

これで、Ectoのリッチなクエリー機能の力を感じられるようになってきました。私たちは `Repo.one/1` を使って、"1" を含むメールアドレスを持つすべてのユーザーのカウントを取得し、期待されるカウントを返してもらいました。これはEctoのクエリーインターフェイスの表面を掻い摘んだだけで、サブクエリー、インターバルクエリー、高度なセレクト文など、より多くの機能がサポートされています。たとえば、すべてのユーザーIDとそのメールアドレスのマップを取得するクエリーを作成してみましょう。

```elixir
iex> Repo.all(from u in User, select: %{u.id => u.email})
[debug] QUERY OK source="users" db=0.9ms
SELECT u0."id", u0."email" FROM "users" AS u0 []
[%{3 => "user1@example.com"}, %{4 => "user2@example.com"}]
```

この小さなクエリーは大きなパンチを持っていました。これは、データベースからすべてのユーザーのメールアドレスをフェッチし、結果のマップを一度に効率的に作成できます。サポートされているクエリー機能の幅の広さを見るには、[Ecto.Query documentation](https://hexdocs.pm/ecto/Ecto.Query.html#content)を参照してください。

挿入に加えて、`Repo.update/1` や `Repo.delete/1` 関数を使って更新や削除を行うこともできます。Ectoはまた、`Repo.insert_all`, `Repo.update_all`, `Repo.delete_all` 関数を使った一括永続化もサポートしています。

Ectoでできることはまだまだたくさんあります。ここまではほんの触りをかじったにすぎません。しっかりとしたEctoの基礎ができたので、アプリの構築を続け、Webアプリケーションとバックエンドの永続化を統合する準備が整いました。途中で、Ectoの知識を広げ、システムの基礎となる詳細からWebインターフェイスを適切に分離する方法を学びます。続きは[Ecto documentation](https://hexdocs.pm/ecto/)をご覧ください。

[コンテキストガイド](contexts.html)では、関連する機能をグループ化したモジュールの背後にあるEctoのアクセスとビジネスロジックをどのようにまとめるかを見ていきます。Phoenixがメンテナンス性の高いアプリケーションの設計にどのように役立っているかを見ていきます。道に沿って他のきちんとしたEctoの機能を見ていくことでしょう。

## MySQLの使用

PhoenixアプリケーションはデフォルトでPostgreSQLを使用するように設定されていますが、代わりにMySQLを使用したい場合はどうすればよいでしょうか？このガイドでは、新しいアプリケーションを作成しようとしている場合でも、既存のアプリケーションがPostgreSQL用に設定されている場合でも、デフォルトを変更する方法を説明します。

新しいアプリケーションを作成しようとしている場合、MySQLを使用するようにアプリケーションを設定するのは簡単です。単に `--database mysql` フラグを `phx.new` に渡すだけで、すべてが正しく設定されます。


```console
$ mix phx.new hello_phoenix --database mysql
```

これにより、正しい依存関係と設定が自動的にセットアップされます。これらの依存関係を `mix deps.get` でインストールすると、アプリケーションでEctoを使い始める準備が整います。

既存のアプリケーションがあれば、アダプターを切り替えてちょっとした設定変更をするだけです。

アダプターを切り替えるには、Postgrexの依存関係を削除し、代わりにMariaex用の新しいものを追加する必要があります。（訳注: MariaexではなくMyXQLが正しいとおもわれる）

それでは、`mix.exs` ファイルを開いて、切り替えてみましょう。

```elixir
defmodule HelloPhoenix.MixProject do
  use Mix.Project

  . . .
  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.4"},
      {:myxql, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
```

次に、デフォルトのMySQL認証情報を使用するようにアダプターを設定する必要があります。`config/dev.exs` ファイルを開いて設定してみましょう。

```elixir
config :hello_phoenix, HelloPhoenix.Repo,
username: "root",
password: "",
database: "hello_phoenix_dev"
```

既存の `HelloPhoenix.Repo` の設定ブロックがあれば、値を変更して新しい値と一致させることができます。また、`config/test.exs` と `config/prod.secret.exs` ファイルにも正しい値を設定する必要があります。

最後の変更点は、`lib/hello_phoenix/repo.ex` を開き、`:adapter` を `Ecto.Adapterers.MyXQL` に設定することです。

あとは新しい依存関係を取得するだけです。

```console
$ mix do deps.get, compile
```

新しいアダプターがインストールされ、設定されたので、データベースを作成する準備が整いました。

```console
$ mix ecto.create
```

HelloPhoenix.repoのデータベースが作成されました。
マイグレーションを実行したり、Ectoを使って他のことをする準備もできています。

```console
$ mix ecto.migrate
[info] == Running HelloPhoenix.Repo.Migrations.CreateUser.change/0 forward
[info] create table users
[info] == Migrated in 0.2s
```

## その他のオプション

Phoenixは[Ectoプロジェクト](https://hexdocs.pm/ecto)を使ってデータアクセスレイヤーと対話していますが、他にも多くのデータアクセスオプションがあり、Erlang標準ライブラリに組み込まれているものもあります。[ETS](http://www.erlang.org/doc/man/ets.html)と[DETS](http://www.erlang.org/doc/man/dets.html)は、[OTP](http://www.erlang.org/doc/)に組み込まれたキーバリューデータストアです。OTPはまた、[mnesia](http://www.erlang.org/doc/man/mnesia.html)というリレーショナルデータベースをQLCと呼ばれる独自のクエリ言語と共に提供しています。ElixirとErlangの両方には、幅広い一般的なデータストアを扱うための多くのライブラリもあります。

データの世界はあなたの思いのままですが、このガイドではこれらのオプションは取り上げません。
