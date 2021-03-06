---
layout: 1.5/layout
version: 1.5
group: guides
title: Mixタスク
nav_order: 9
hash: 629a2fb4
---
# Mixタスク

現在、新しく生成されたアプリケーション内で利用可能な、組み込みのPhoenix固有のタスクとEcto固有のMixタスクが多数存在します。また、独自のアプリケーション固有のタスクを作成することもできます。

> 注：`mix` について詳しく知りたい方は、Elixirの公式の[Mix入門](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)を参照してください。

## Phoenixタスク

```console
➜ mix help --search "phx"
mix local.phx          # Updates the Phoenix project generator locally
mix phx                # Prints Phoenix help information
mix phx.digest         # Digests and compresses static files
mix phx.digest.clean   # Removes old versions of static assets.
mix phx.gen.cert       # Generates a self-signed certificate for HTTPS testing
mix phx.gen.channel    # Generates a Phoenix channel
mix phx.gen.context    # Generates a context with functions around an Ecto schema
mix phx.gen.embedded   # Generates an embedded Ecto schema file
mix phx.gen.html       # Generates controller, views, and context for an HTML resource
mix phx.gen.json       # Generates controller, views, and context for a JSON resource
mix phx.gen.presence   # Generates a Presence tracker
mix phx.gen.schema     # Generates an Ecto schema and migration file
mix phx.gen.secret     # Generates a secret
mix phx.new            # Creates a new Phoenix application
mix phx.new.ecto       # Creates a new Ecto project within an umbrella project
mix phx.new.web        # Creates a new Phoenix web project within an umbrella project
mix phx.routes         # Prints all routes
mix phx.server         # Starts applications and their servers
```

ガイドの中でも1度は目にしたことがありますが、それらの情報が1箇所に持っていることは良いことのように思えます。

ここでは、Phoenixインストーラーの一部である `phx.new`, `phx.new.ecto`, `phx.new.web` を除いたPhoenix Mixタスクを扱います。これらのタスクや他のタスクについては、`mix help TASK` を呼び出すことで詳しく知ることができます。
### `mix phx.gen.html`

Phoenixは、完全なHTMLリソースを立ち上げるためのすべてのコードを生成する機能を提供します。生成されるのはectoマイグレーション、ectoコンテキスト、必要なすべてのアクション、ビュー、テンプレートを持つコントローラーです。これは、とてつもなく時間を節約できます。これを実現する方法を見てみましょう。

`mix phx.gen.html` タスクはいくつかの引数をとります。コンテキストのモジュール名、スキーマのモジュール名、リソース名、そしてcolumn_name:type属性のリストです。私たちが渡すモジュール名は適切な大文字から始まり、Elixirのモジュール名のルールに準拠していなければなりません。

```console
$ mix phx.gen.html Blog Post posts body:string word_count:integer
* creating lib/hello_web/controllers/post_controller.ex
* creating lib/hello_web/templates/post/edit.html.eex
* creating lib/hello_web/templates/post/form.html.eex
* creating lib/hello_web/templates/post/index.html.eex
* creating lib/hello_web/templates/post/new.html.eex
* creating lib/hello_web/templates/post/show.html.eex
* creating lib/hello_web/views/post_view.ex
* creating test/hello_web/controllers/post_controller_test.exs
* creating lib/hello/blog/post.ex
* creating priv/repo/migrations/20170906150129_create_posts.exs
* creating lib/hello/blog.ex
* injecting lib/hello/blog.ex
* creating test/hello/blog/blog_test.exs
* injecting test/hello/blog/blog_test.exs
```

ファイルの作成が終わると、`mix phx.gen.html` は、ectoマイグレーションを実行するのと同様に、ルーターファイルに1行を追加する必要があることを教えてくれます。

```console
Add the resource to your browser scope in lib/hello_web/router.ex:

    resources "/posts", PostController

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

重要: これを行わないと、ログに以下のような警告が表示され、関数を実行しようとするとアプリケーションがエラーになります。

```console
$ mix phx.server
Compiling 17 files (.ex)

warning: function HelloWeb.Router.Helpers.post_path/3 is undefined or private
  lib/hello_web/controllers/post_controller.ex:22:
```

リソースのコンテキストやスキーマを作成したくない場合は、`--no-context` フラグを使うことができます。この場合でも、パラメーターとしてコンテキストモジュール名が必要になることに注意しましょう。

```console
$ mix phx.gen.html Blog Post posts body:string word_count:integer --no-context
* creating lib/hello_web/controllers/post_controller.ex
* creating lib/hello_web/templates/post/edit.html.eex
* creating lib/hello_web/templates/post/form.html.eex
* creating lib/hello_web/templates/post/index.html.eex
* creating lib/hello_web/templates/post/new.html.eex
* creating lib/hello_web/templates/post/show.html.eex
* creating lib/hello_web/views/post_view.ex
* creating test/hello_web/controllers/post_controller_test.exs
```

ルーターファイルに行を追加する必要があることを教えてくれますが、コンテキストをスキップしたので、`ecto.migrate` については何も言及してくれません。


```console
Add the resource to your browser scope in lib/hello_web/router.ex:

    resources "/posts", PostController
```

同様に、リソースのスキーマなしでコンテキストを作成したい場合は `--no-schema` フラグを使うことができます。

```console
$ mix phx.gen.html Blog Post posts body:string word_count:integer --no-schema
* creating lib/hello_web/controllers/post_controller.ex
* creating lib/hello_web/templates/post/edit.html.eex
* creating lib/hello_web/templates/post/form.html.eex
* creating lib/hello_web/templates/post/index.html.eex
* creating lib/hello_web/templates/post/new.html.eex
* creating lib/hello_web/templates/post/show.html.eex
* creating lib/hello_web/views/post_view.ex
* creating test/hello_web/controllers/post_controller_test.exs
* creating lib/hello/blog.ex
* injecting lib/hello/blog.ex
* creating test/hello/blog/blog_test.exs
* injecting test/hello/blog/blog_test.exs
```

ルーターファイルに行を追加する必要があることを教えてくれますが、スキーマをスキップしているので、 `ecto.migrate` については何も言及していません。

### `mix phx.gen.json`

また、Phoenixは、完全なJSONリソースを立ち上げるためのすべてのコードを生成する機能を提供しています。生成されるのはectoマイグレーション、ectoスキーマ、すべての必要なアクションとビューを持つコントローラーです。このコマンドは、アプリのテンプレートを作成しません。

`mix phx.gen.json` タスクはいくつかの引数をとります。コンテキストのモジュール名、スキーマのモジュール名、リソース名、そしてcolumn_name:type属性のリストです。私たちが渡すモジュール名は適切な大文字から始まり、Elixirのモジュール名のルールに準拠していなければなりません。

```console
$ mix phx.gen.json Blog Post posts title:string content:string
* creating lib/hello_web/controllers/post_controller.ex
* creating lib/hello_web/views/post_view.ex
* creating test/hello_web/controllers/post_controller_test.exs
* creating lib/hello_web/views/changeset_view.ex
* creating lib/hello_web/controllers/fallback_controller.ex
* creating lib/hello/blog/post.ex
* creating priv/repo/migrations/20170906153323_create_posts.exs
* creating lib/hello/blog.ex
* injecting lib/hello/blog.ex
* creating test/hello/blog/blog_test.exs
* injecting test/hello/blog/blog_test.exs
```

`mix phx.gen.json` がファイルの作成を終えると、ectoマイグレーションを実行するのと同様に、ルーターファイルに1行を追加する必要があることを教えてくれます。

```console
Add the resource to your :api scope in lib/hello_web/router.ex:

    resources "/posts", PostController, except: [:new, :edit]

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

重要: これを行わないと、ログに以下のような警告が表示され、ページを読み込もうとするとアプリケーションがエラーになります。

```console
$ mix phx.server
Compiling 19 files (.ex)

warning: function HelloWeb.Router.Helpers.post_path/3 is undefined or private
  lib/hello_web/controllers/post_controller.ex:18
```

`mix phx.gen.json` は `mix phx.gen.html` と同様に `--no-context`, `--no-schema` などもサポートしています。
### `mix phx.gen.context`

完全なHTML/JSONリソースを必要とせず、代わりにコンテキストだけに興味がある場合、`mix phx.gen.context` タスクを使うことができます。これはコンテキスト、スキーマ、マイグレーション、テストケースを生成します。

`mix phx.gen.context` タスクはいくつかの引数を取ります。コンテキストのモジュール名、スキーマのモジュール名、リソース名、column_name:type属性のリストを受け取ります。

```console
$ mix phx.gen.context Accounts User users name:string age:integer
* creating lib/hello/accounts/user.ex
* creating priv/repo/migrations/20170906161158_create_users.exs
* creating lib/hello/accounts.ex
* injecting lib/hello/accounts.ex
* creating test/hello/accounts/accounts_test.exs
* injecting test/hello/accounts/accounts_test.exs
```

> 注意: リソースを名前空間にする必要がある場合は、単にジェネレーターの第一引数を名前空間にできます。

```console
* creating lib/hello/admin/accounts/user.ex
* creating priv/repo/migrations/20170906161246_create_users.exs
* creating lib/hello/admin/accounts.ex
* injecting lib/hello/admin/accounts.ex
* creating test/hello/admin/accounts/accounts_test.exs
* injecting test/hello/admin/accounts/accounts_test.exs
```

### `mix phx.gen.schema`

完全なHTML/JSONリソースを必要とせず、コンテキストの生成や変更に興味がない場合、`mix phx.gen.schema` タスクを使うことができます。これはスキーマとマイグレーションを生成します。

`mix phx.gen.schema` タスクはいくつかの引数を取ります。スキーマのモジュール名（名前空間を持つこともあります）、リソース名、column_name:type属性のリストを受け取ります。

```console
$ mix phx.gen.schema Accounts.Credential credentials email:string:unique user_id:references:users
* creating lib/hello/accounts/credential.ex
* creating priv/repo/migrations/20170906162013_create_credentials.exs
```

### `mix phx.gen.channel`

このタスクは、基本的なPhoenixチャンネルとテストケースを生成します。このタスクはチャンネルのモジュール名を引数にとります。

```console
$ mix phx.gen.channel Room
* creating lib/hello_web/channels/room_channel.ex
* creating test/hello_web/channels/room_channel_test.exs
```

`mix phx.gen.channel` が完了すると、ルーターファイルにチャンネルルートを追加する必要があることを教えてくれます。

```console
Add the channel to your `lib/hello_web/channels/user_socket.ex` handler, for example:

    channel "rooms:lobby", HelloWeb.RoomChannel
```

### `mix phx.gen.presence`

このタスクはプレゼンストラッカーを生成します。引数としてモジュール名を渡すことができ、モジュール名を渡さない場合は `Presence` が用いられます。

```console
$ mix phx.gen.presence Presence
$ lib/hello_web/channels/presence.ex
```

### `mix phx.routes`

このタスクの目的は1つで、あるルーターに対して定義されたすべてのルートを表示することです。[ルーティングガイド](routing.html)で広く使われているのを見ました。

このタスクにルーターを指定しない場合、Phoenixが生成してくれたルーターがデフォルトになります。

```console
$ mix phx.routes
page_path  GET  /  TaskTester.PageController.index/2
```
また、アプリケーションに複数のルーターがある場合は、個々のルーターを指定することもできます。

```console
$ mix phx.routes TaskTesterWeb.Router
page_path  GET  /  TaskTesterWeb.PageController.index/2
```

### `mix phx.server`

これはアプリケーションを起動するために使用するタスクです。これは引数を一切取りません。何か引数を渡しても、それは静かに無視されます。

```console
$ mix phx.server
[info] Running TaskTesterWeb.Endpoint with Cowboy on port 4000 (http)
```
引数 `DoesNotExist` を黙って無視します。

```console
$ mix phx.server DoesNotExist
[info] Running TaskTesterWeb.Endpoint with Cowboy on port 4000 (http)
```
アプリケーションを起動して `iex` セッションを開きたい場合は、`iex` 内でMixタスクを次のように実行できます。

```console
$ iex -S mix phx.server
Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

[info] Running TaskTesterWeb.Endpoint with Cowboy on port 4000 (http)
Interactive Elixir (1.0.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

### `mix phx.digest`

このタスクは2つのことを行います。静的アセットのダイジェストを作成し、圧縮します。

ここでいう「ダイジェスト」とは、アセットの内容をMD5によってダイジェストしたもので、アセットのファイル名に追加されます。これにより、一種の「フィンガープリント」が作成されます。ダイジェストが変更されなければ、ブラウザやCDNはキャッシュされたバージョンを使用します。ダイジェストが変更された場合は、新しいバージョンを再取得します。

このタスクを実行する前に、helloアプリケーションの2つのディレクトリの内容を調べてみましょう。

最初の `priv/static` は以下のようになっているはずです。

```console
├── images
│   └── phoenix.png
├── robots.txt
```

そして、`assets/` は以下のようになります。

```console
├── css
│   └── app.scss
├── js
│   └── app.js
├── vendor
│   └── phoenix.js
```

これらのファイルはすべて静的アセットです。それでは `mix phx.digest` タスクを実行してみましょう。

```console
$ mix phx.digest
Check your digested files at 'priv/static'.
```

タスクが示すように、`priv/static` ディレクトリの内容を検査できます。 `assets/` のすべてのファイルが `priv/static` にコピーされ、各ファイルにはいくつかのバージョンがあることがわかります。それらのバージョンは次の通りです。

* 元ファイル
* gzip圧縮されたファイル
* 元のファイル名とそのダイジェストを含むファイル
* ファイル名とそのダイジェストを含む圧縮ファイル

オプションで、設定ファイルの `:gzippable_exts` オプションを使って、どのファイルを圧縮するかを決めることができます。

```elixir
config :phoenix, :gzippable_exts, ~w(.js .css)
```

> 注意: `mix phx.digest` が処理されたファイルを置く別の出力フォルダを指定できます。第一引数は静的ファイルが置かれているパスです。

```console
$ mix phx.digest priv/static -o www/public
Check your digested files at 'www/public'.
```

## Ectoタスク

新しく生成されたPhoenixアプリケーションは、デフォルトでectoとpostgrexを依存関係として含んでいます（`mix phx.new` に `--no-ecto` フラグを付けて使わない限り）。これらの依存関係には、一般的なectoの操作を行うためのMixタスクが含まれています。どのようなタスクがあるのか見てみましょう。

```console
$ mix help --search "ecto"
mix ecto               # Prints Ecto help information
mix ecto.create        # Creates the repository storage
mix ecto.drop          # Drops the repository storage
mix ecto.dump          # Dumps the repository database structure
mix ecto.gen.migration # Generates a new migration for the repo
mix ecto.gen.repo      # Generates a new repository
mix ecto.load          # Loads previously dumped database structure
mix ecto.migrate       # Runs the repository migrations
mix ecto.migrations    # Displays the repository migration status
mix ecto.rollback      # Rolls back the repository migrations
```

注意: アプリケーションを起動せずにタスクを実行するには、`--no-start` フラグを付けて上記のタスクを実行できます。

### `mix ecto.create`

このタスクはレポで指定されたデータベースを作成します。デフォルトでは、アプリケーションの名前のついたレポ(ectoをオプトアウトしていない限り、アプリケーションで生成されたもの)を探しますが、必要に応じて別のレポを渡すこともできます。

実際の動作は以下のようになります。

```console
$ mix ecto.create
The database for Hello.Repo has been created.
```

`ecto.create` でうまくいかないことがいくつかあります。Postgresデータベースに "postgres" ロール（ユーザー）がない場合、このようなエラーが発生します。

```console
$ mix ecto.create
** (Mix) The database for Hello.Repo couldn't be created, reason given: psql: FATAL:  role "postgres" does not exist
```

ログインしてデータベースを作成するために必要なパーミッションを持った "postgres" ロールを `psql` コンソールにて作成することで、これを修正できます。

```console
=# CREATE ROLE postgres LOGIN CREATEDB;
CREATE ROLE
```

"postgres"ロールがアプリケーションにログインする権限を持っていない場合、このようなエラーが発生します。

```console
$ mix ecto.create
** (Mix) The database for Hello.Repo couldn't be created, reason given: psql: FATAL:  role "postgres" is not permitted to log in
```

これを修正するには、"postgres"ユーザーのパーミッションを変更してログインを許可する必要があります。

```console
=# ALTER ROLE postgres LOGIN;
ALTER ROLE
```

"postgres"ロールがデータベースを作成する権限を持っていない場合、このようなエラーが発生します。

```console
$ mix ecto.create
** (Mix) The database for Hello.Repo couldn't be created, reason given: ERROR:  permission denied to create database
```

これを修正するには、`psql` コンソールで"postgres"ユーザーのパーミッションを変更して、データベースの作成を許可する必要があります。

```console
=# ALTER ROLE postgres CREATEDB;
ALTER ROLE
```

"postgres"ロールがデフォルトの"postgres"とは異なるパスワードを使用している場合、このエラーが発生します。

```console
$ mix ecto.create
** (Mix) The database for Hello.Repo couldn't be created, reason given: psql: FATAL:  password authentication failed for user "postgres"
```

これを修正するには、環境固有の設定ファイルでパスワードを変更します。開発環境で使用するパスワードは `config/dev.exs` ファイルの一番下にあります。

最後に、データベースを作成したい `OurCustom.Repo` という名前のレポがある場合は、次のように実行します。
```console
$ mix ecto.create -r OurCustom.Repo
The database for OurCustom.Repo has been created.
```

### `mix ecto.drop`

このタスクはレポで指定したデータベースを削除します。デフォルトでは、私たちのアプリケーションにちなんだレポを探します（ectoをオプトアウトしない限り、私たちのアプリケーションで生成されたもの）。dbを削除するかどうかを確認するためのプロンプトは表示されませんので、注意してください。

```console
$ mix ecto.drop
The database for Hello.Repo has been dropped.
```

たまたまデータベースを削除したいレポがあった場合は、`-r` フラグで指定します。

```console
$ mix ecto.drop -r OurCustom.Repo
The database for OurCustom.Repo has been dropped.
```

### `mix ecto.gen.repo`

多くのアプリケーションでは複数のデータストアを必要とします。それぞれのデータストアに対して新しいレポが必要で、`ecto.gen.repo` で自動的に生成できます。

レポの名前を `OurCustom.Repo` とすると、このタスクは `lib/our_custom/repo.ex` という名前でレポを作成します。

```console
$ mix ecto.gen.repo -r OurCustom.Repo
* creating lib/our_custom
* creating lib/our_custom/repo.ex
* updating config/config.exs
Don't forget to add your new repo to your supervision tree
(typically in lib/hello.ex):

    children = [
      ...,
      OurCustom.Repo,
      ...
    ]
```

このタスクは `config/config.exs` を更新していることに注目してください。見てみると、新しいレポ用に追加された設定ブロックが見えます。

```elixir
. . .
config :hello, OurCustom.Repo,
  database: "hello_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"
. . .
```

もちろん、ログインクレデンシャルをデータベースが期待するものと一致するように変更する必要があります。また、他の環境用に設定を変更する必要があります。

指示にしたがって、新しいレポを監視ツリーに追加する必要があります。私たちの `Hello` アプリケーションでは、`lib/hello.ex` を開き、私たちのレポをworkerとして `children` リストに追加します。

```elixir
. . .
children = [
  # Start the Ecto repository
  Hello.Repo,
  # Our custom repo
  OurCustom.Repo,
  # Start the endpoint when the application starts
  HelloWeb.Endpoint,
]
. . .
```

### `mix ecto.gen.migration`

マイグレーションは、データベーススキーマへの変更に影響を与えるためのプログラム的で繰り返し可能な方法です。マイグレーションは単なるモジュールであり、`ecto.gen.migration` タスクで作成できます。新しいコメントテーブルのためのマイグレーションを作成する手順を見てみましょう。

タスクを起動するには、必要なモジュール名のsnake_caseバージョンを指定するだけです。この名前にはマイグレーションで何をするかを記述することが望ましいです。

```console
mix ecto.gen.migration add_comments_table
* creating priv/repo/migrations
* creating priv/repo/migrations/20150318001628_add_comments_table.exs
```

マイグレーションのファイル名は、ファイルが作成された日時を表す文字列で始まることに注目してください。

`priv/repo/migrations/20150318001628_add_comments_table.exs` にある `ecto.gen.migration` が生成したファイルを見てみましょう。

```elixir
defmodule Hello.Repo.Migrations.AddCommentsTable do
  use Ecto.Migration

  def change do
  end
end
```

単一の関数 `change/0` があり、これはフォワードとロールバックの両方を処理します。ectoの便利なDSLを使ってスキーマの変更を定義し、ロールフォワードかロールバックかによって何をすべきかを判断します。非常に良いですね。

ここでやりたいことは、`body` カラム、`word_count` カラム、そして `inserted_at` と `updated_at` のタイムスタンプカラムを持つ `comments` テーブルを作成することです。

```elixir
. . .
def change do
  create table(:comments) do
    add :body,       :string
    add :word_count, :integer
    timestamps()
  end
end
. . .
```

繰り返しになりますが、このタスクは `-r` フラグと必要に応じて別のレポを使って実行できます。

```console
$ mix ecto.gen.migration -r OurCustom.Repo add_users
* creating priv/repo/migrations
* creating priv/repo/migrations/20150318172927_add_users.exs
```

データベーススキーマを変更する方法の詳細についてはectoのマイグレーションDSL（[ecto migrationドキュメント](https://hexdocs.pm/ecto_sql/Ecto.Migration.html)）を参照してください。
たとえば、既存のスキーマを変更するには、ectoの[`alter/2`](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#alter/2) 関数を使用しています。

これで完了です！マイグレーションを実行する準備ができました。

### `mix ecto.migrate`

マイグレーションモジュールの準備ができたら、`mix ecto.migrate` を実行して、変更をデータベースに適用します。

```console
$ mix ecto.migrate
[info] == Running Hello.Repo.Migrations.AddCommentsTable.change/0 forward
[info] create table comments
[info] == Migrated in 0.1s
```

最初に `ecto.migrate` を実行すると、`schema_migrations` というテーブルが作成されます。これは、マイグレーションのファイル名のタイムスタンプ部分を保存することで、実行したすべてのマイグレーションを追跡します。

テーブル `schema_migrations` は以下のようになっています。

```console
hello_dev=# select * from schema_migrations;
version        |     inserted_at
---------------+---------------------
20150317170448 | 2015-03-17 21:07:26
20150318001628 | 2015-03-18 01:45:00
(2 rows)
```

マイグレーションをロールバックすると、`ecto.rollback` はそのマイグレーションを表すレコードを `schema_migrations` から削除します。

デフォルトでは、`ecto.migrate` は保留中のすべてのマイグレーションを実行します。タスクの実行時にいくつかのオプションを指定することで、どのマイグレーションを実行するかを制御できます。

`-n` または `--step` オプションを用いて、実行したい保留中のマイグレーションの数を指定できます。

```console
$ mix ecto.migrate -n 2
[info] == Running Hello.Repo.Migrations.CreatePost.change/0 forward
[info] create table posts
[info] == Migrated in 0.0s
[info] == Running Hello.Repo.Migrations.AddCommentsTable.change/0 forward
[info] create table comments
[info] == Migrated in 0.0s
```

`--step` オプションも同じように動作します。

```console
mix ecto.migrate --step 2
```

`to` オプションは、指定されたバージョンまでのすべてのマイグレーションを実行します。

```console
mix ecto.migrate --to 20150317170448
```

### `mix ecto.rollback`

`ecto.rollback` タスクは最後に実行したマイグレーションを逆にして、スキーマの変更を元に戻します。`ecto.migrate` と `ecto.rollback` は互いにミラーイメージです。

```console
$ mix ecto.rollback
[info] == Running Hello.Repo.Migrations.AddCommentsTable.change/0 backward
[info] drop table comments
[info] == Migrated in 0.0s
```

`ecto.rollback` は `ecto.migrate` と同じオプションを扱うので、`-n`, `--step`, `-v`, `--to` は `ecto.migrate` と同じように動作します。

## 独自のMixタスクを作成する

このガイドで見てきたように、mix自体も、アプリケーションに持ち込む依存関係も、本当に便利なタスクを無料で提供してくれます。これらのいずれも、個々のアプリケーションのすべてのニーズを予測することはできませんが、mixでは独自のカスタムタスクを作成できます。これがまさにこれからやろうとしていることです。

最初にすべきことは、`lib` の中に `mix/tasks` ディレクトリを作ることです。ここにアプリケーション固有のMixタスクを作成します。

```console
$ mkdir -p lib/mix/tasks
```

そのディレクトリの中に、次のような `hello.greeting.ex` という新しいファイルを作成してみましょう。

```elixir
defmodule Mix.Tasks.Hello.Greeting do
  use Mix.Task

  @shortdoc "Sends a greeting to us from Hello Phoenix"

  @moduledoc """
  This is where we would put any long form documentation or doctests.
  """

  def run(_args) do
    Mix.shell().info("Greetings from the Hello Phoenix Application!")
  end

  # We can define other functions as needed here.
end
```

ここでは、作成中のMixタスクに含まれる動的な部分を簡単に見てみましょう。

最初にすべきことは、モジュールの名前を付けることです。すべてのタスクは `Mix.Tasks` 名前空間で定義する必要があります。これを `mix hello.greeting` として呼び出したいので、モジュール名を `Hello.Greeting` と命名します。

`use Mix.Task` 行は、このモジュールをMixタスクとして動作させるMixの機能をもたらします。

モジュール属性 `@shortdoc` は、ユーザーが `mix help` を起動したときのタスクを説明する文字列を保持します。

`moduledoc` は他のモジュールと同じ機能を果たします。長文のドキュメントやdoctestがあれば、ここに置くことができます。

関数 `run/1` はMixタスクの重要な心臓部です。これは、ユーザーがタスクを起動したときにすべての作業を行う関数です。我々のタスクでは、アプリから挨拶を送るだけですが、`run/1` 関数を実装することで、必要なことを何でも行うことができます。`Mix.shell().info/1` は、ユーザーへテキストを出力するのに好ましい方法であることに注目してください。

もちろん、このタスクは単なるモジュールなので、`run/1` 関数をサポートするために必要に応じて他のプライベート関数を定義できます。

タスクモジュールを定義したので、次のステップはアプリケーションをコンパイルすることです。

```console
$ mix compile
Compiled lib/tasks/hello.greeting.ex
Generated hello.app
```

これで新しいタスクが `mix help` に表示されるようになりました。

```console
$ mix help --search hello
mix hello.greeting # Sends a greeting to us from Hello Phoenix
```

`mix help` は `@shortdoc` に入力したテキストとタスク名を表示していることに注目してください。

ここまでは順調ですが、うまくいくでしょうか？

```console
$ mix hello.greeting
Greetings from the Hello Phoenix Application!
```

確かに動作しました。

新しいMixタスクでアプリケーションのインフラストラクチャを使用するようにしたい場合、Mixタスクが実行されているときにアプリケーションが起動しているようにする必要があります。これは、Mixタスク内からデータベースへアクセスする必要がある場合にとくに便利です。ありがたいことに、mixはそれを本当に簡単にしてくれます。

```elixir
  . . .
  def run(_args) do
    Mix.Task.run("app.start")
    Mix.shell().info("Now I have access to Repo and other goodies!")
  end
  . . .
```
