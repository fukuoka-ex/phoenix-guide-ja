---
layout: 1.4/layout
version: 1.4
group: testing
title: スキーマのテスト
nav_order: 2
hash: 5d132fdb587634ec2322586785b1408886481beb
---
# スキーマのテスト

[Ectoガイド](../ecto.html)では、ユーザーのためのHTMLリソースを生成しました。これにより、ユーザースキーマとユーザースキーマテストケースを含む多くのモジュールをただで提供してくれます。このガイドでは、スキーマとテストケースを使って、Ectoガイドで行った変更をテスト駆動型の方法で作業します。

Ectoガイドをまだ作業していない人が、追いつくのは簡単です。下記の「HTMLリソースの生成」をご覧ください。

変更を加える前に、`mix test`を実行してテストスイートがきれいに動作することを確認しましょう。

```console
$ mix test
................

Finished in 0.6 seconds
19 tests, 0 failures

Randomized with seed 638414
```

いいですね。19件のテストがあり、すべて成功しています!

## チェンジセットのテスト駆動

スキーマモジュールに追加のバリデーションを追加する予定なので、生成された `test/hello/accounts/accounts_test.exs` を開いて見てみましょう。

```elixir
defmodule Hello.AccountsTest do
  use Hello.DataCase

  alias Hello.Accounts

  describe "users" do
    alias Hello.Accounts.User

    @valid_attrs %{bio: "some bio", email: "some email", name: "some name", number_of_pets: 42}
    @update_attrs %{bio: "some updated bio", email: "some updated email", name: "some updated name", number_of_pets: 43}
    @invalid_attrs %{bio: nil, email: nil, name: nil, number_of_pets: nil}

    # ...

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.bio == "some bio"
      assert user.email == "some email"
      assert user.name == "some name"
      assert user.number_of_pets == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    # ...
  end
end
```

最初の行では、`test/support/data_case.ex`で定義されている`Hello.DataCase`を使います。`Hello.DataCase`はスキーマケースに必要なモジュールのインポートとエイリアスを行います。`Hello.DataCase`はまた、すべてのスキーマテストをSQLサンドボックス内で実行し、テストの終わりにデータベースへの変更を元に戻します。

> PostgreSQLを使用している場合は、`use Hello.DataCase, async: true`を設定することで、データベースのテストを非同期に実行することもできますが、他のデータベースではこのオプションは推奨されません。

`Hello.DataCase`はスキーマをテストするために必要なヘルパー関数を定義する場所でもあります。たとえば、ただで手に入る関数`errors_on/1`があり、それがどのように動作するかをまもなく見てみましょう。

`Hello.Accounts.User`モジュールの構造体を`%Hello.Accounts.User{}`ではなく`%User{}`として参照できるように、`Hello.Accounts.User`モジュールのエイリアスを設定します。

また、`@valid_attrs`と`@invalid_attrs`のモジュール属性を定義し、すべてのテストで利用できるようにします。

#### ペットの数

Phoenixは必要なフィールドをすべて備えたモデルを生成しましたが、ユーザーが飼っているペットの数はここではオプションとします。

それを検証するために新しいテストを書いてみましょう。

これをテストするには、`@valid_attrs`マップから`:number_of_pets`のキーと値を削除し、これらの新しい属性から `User`チェンジセットを作成します。そうすれば、そのチェンジセットがまだ有効であることが保証されます。

```elixir
defmodule Hello.AccountsTest do
  ...

  test "number_of_pets is not required" do
    changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :number_of_pets))
    assert changeset.valid?
  end
end
```

では、もう一度テストを実行してみましょう。

```console
$ mix test
....................

  1) test number_of_pets is not required (Hello.AccountsTest)
     test/hello/accounts/accounts_test.exs:19
     Expected truthy, got false
     code: assert changeset.valid?()
     stacktrace:
       test/hello/accounts/accounts_test.exs:21: (test)
..

Finished in 0.4 seconds
20 tests, 1 failure

Randomized with seed 780208
```

`validate_required/3` function in `lib/hello_web/accounts/user.ex`.
失敗しました。まさにその通り! これを成功させるコードはまだ書いていません。そのためには、`lib/hello_web/accounts/user.ex`の`validate_required/3`関数から`:number_of_pets`属性を削除する必要があります。

```elixir
defmodule Hello.Accounts.User do
  ...

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
  end
end
```

これでテストはすべて成功しました。

```console
$ mix test
.......................

Finished in 0.3 seconds
20 tests, 0 failures

Randomized with seed 963040
```

#### 自己紹介属性

Ectoガイドでは、ユーザの`:bio`属性には2つのビジネス要件があることとして学びました。1つ目は、少なくとも2文字以上の長さでなければならないということです。先ほどと同じパターンを使ってテストを書いてみましょう。

まず、`:bio`属性を一文字の値を持つように変更します。次に、新しい属性でチェンジセットを作成し、その妥当性をテストします。

```elixir
defmodule Hello.AccountsTest do
  ...

  test "bio must be at least two characters long" do
    attrs = %{@valid_attrs | bio: "I"}
    changeset = User.changeset(%User{}, attrs)
    refute changeset.valid?
  end
end
```

テストを実行すると、予想通り失敗します。

```console
$ mix test
...................

  1) test bio must be at least two characters long (Hello.AccountsTest)
     test/hello/accounts/accounts_test.exs:24
     Expected false or nil, got true
     code: refute changeset.valid?()
     stacktrace:
       test/hello/accounts/accounts_test.exs:27: (test)

....

Finished in 0.3 seconds
21 tests, 1 failure

Randomized with seed 327779
```

うーん。はい、このテストは期待通りに動作しましたが、エラーメッセージはテストを反映していないようです。私たちは`:bio`属性の長さを検証していますが、得られるメッセージは"Expected false or nil, got true"です。これでは、`:bio`属性についてはちっとも言及されていません。

私たちはもっとうまくやれるはずです。

同じ動作をテストしながら、より良いメッセージを得るためにテストを変更してみましょう。新しい`:bio`の値を設定するコードはそのままにしておいても構いません。しかし、`assert`では `DataCase` から得た`errors_on/1` 関数を用いてエラーのマップを生成し、そのマップに `:bio` 属性のエラーがあることを確認します。

```elixir
defmodule Hello.AccountsTest do
  ...

  test "bio must be at least two characters long" do
    attrs = %{@valid_attrs | bio: "I"}
    changeset = User.changeset(%User{}, attrs)
    assert %{bio: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end
end
```

再度テストを実行すると、全く異なるメッセージが表示されます。

```console
$ mix test
...................

  1) test bio must be at least two characters long (Hello.AccountsTest)
     test/hello/accounts/accounts_test.exs:24
     match (=) failed
     code:  assert %{bio: ["should be at least 2 character(s)"]} = errors_on(changeset)
     right: %{}
     stacktrace:
       test/hello/accounts/accounts_test.exs:27: (test)

....

Finished in 0.4 seconds
21 tests, 1 failure

Randomized with seed 435902
```

これは、私たちがテストしているアサーションを示しています。つまり、私たちのエラーがモデルのチェンジセットからのエラーのマップにあることを示しています。

```console
code:  assert %{bio: ["should be at least 2 character(s)"]} = errors_on(changeset)
```

そして、式の右辺が空のマップに評価されることがわかります。

```console
rhs:  %{}
```

まだ`:bio`属性の最小長さのバリデーションをしていないので、マップは空になっています。

私たちのテストは道を指し示しています。では、そのバリデーションを追加して成功させましょう。

```elixir
defmodule Hello.Accounts.User do
  ...

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
    |> validate_length(:bio, min: 2)
  end
end
```

再度テストを実行すると、すべて成功します。

```console
$ mix test
........................

Finished in 0.2 seconds
21 tests, 0 failures

Randomized with seed 305958
```

もう一つのビジネス要件は`:bio`フィールドの最大文字数が140文字であることです。もう一度`errors_on/1`関数を使ってテストを書いてみましょう。

ここではString.duplicate/2を使用して、長さが140の"a"文字列を生成します。

```elixir
defmodule Hello.AccountsTest do
  ...

  test "bio must be at most 140 characters long" do
    attrs = %{@valid_attrs | bio: String.duplicate("a", 141)}
    changeset = User.changeset(%User{}, attrs)
    assert %{bio: ["should be at most 140 character(s)"]} = errors_on(changeset)
  end
end
```

テストを実行すると、予想通り失敗します。

```console
$ mix test
.......................

  1) test bio must be at most 140 characters long (Hello.AccountsTest)
     test/hello/accounts/accounts_test.exs:30
     match (=) failed
     code:  assert %{bio: ["should be at most 140 character(s)"]} = errors_on(changeset)
     right: %{}
     stacktrace:
       test/hello/accounts/accounts_test.exs:33: (test)

.

Finished in 0.3 seconds
22 tests, 1 failure

Randomized with seed 593838
```

このテストを成功させるには、`:bio`属性の長さのバリデーションに最大値を追加する必要があります。

```elixir
defmodule Hello.Accounts.User do
  ...

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
    |> validate_length(:bio, min: 2, max: 140)
  end
end
```

テストを実行すると、すべて成功します。

```console
$ mix test
.........................

Finished in 0.4 seconds
22 tests, 0 failures

Randomized with seed 468975
```

#### Eメール属性

最後に検証すべき属性が一つあります。現在のところ、`:email`は他のものと同じようにただの文字列です。少なくとも"@"と一致することを確認したいと思います。これはEメールの確認の代わりにはなりませんが、試してみる前に無効なアドレスを除外することができます。

このプロセスはもうお馴染みのものになっているでしょう。まず、`:email`属性の値を変更して"@"を省略します。次に、`:email`属性の検証エラーが正しいかどうかを調べるために`errors_on/1`を使うアサーションを書きます。

```elixir
defmodule Hello.AccountsTest do
  ...

  test "email must contain at least an @" do
    attrs = %{@valid_attrs | email: "fooexample.com"}
    changeset = User.changeset(%User{}, attrs)
    assert %{email: ["has invalid format"]} = errors_on(changeset)
  end
end
```

テストを実行すると失敗します。エラーのマップが`errors_on/1`から空になって返ってきていることがわかります。

```console
$ mix test
.......................

  1) test email must contain at least an @ (Hello.AccountsTest)
     test/hello/accounts/accounts_test.exs:36
     match (=) failed
     code:  assert %{email: ["has invalid format"]} = errors_on(changeset)
     right: %{}
     stacktrace:
       test/hello/accounts/accounts_test.exs:39: (test)

..

Finished in 0.4 seconds
23 tests, 1 failure

Randomized with seed 962127
```

次に、テストが求めるエラーを生成するための新しいバリデーションを追加します。

```elixir
defmodule Hello.Accounts.User do
  ...

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :number_of_pets])
    |> validate_required([:name, :email, :bio])
    |> validate_length(:bio, min: 2, max: 140)
    |> validate_format(:email, ~r/@/)
  end
end
```

スキーマのテストは再び成功していますが、生成されたコンテキストとコントローラーのテストに触れていない場合、他のテストは失敗しています。ここでは失敗の例を一つみてみます(ただし、テストはランダムな順番で実行されるので、最初に別の失敗を見ることになるかもしれません)。

```console
$ mix test
....

  1) test update user renders errors when data is invalid (HelloWeb.UserControllerTest)
     test/hello_web/controllers/user_controller_test.exs:66
     ** (MatchError) no match of right hand side value: {:error, #Ecto.Changeset<action: :insert, changes: %{bio: "some bio", email: "some email", name: "some name", number_of_pets: 42}, errors: [email: {"has invalid format", [validation: :format]}], data: #Hello.Accounts.User<>, valid?: false>}
     stacktrace:
       test/hello_web/controllers/user_controller_test.exs:11: HelloWeb.UserControllerTest.fixture/1
       test/hello_web/controllers/user_controller_test.exs:85: HelloWeb.UserControllerTest.create_user/1
       test/hello_web/controllers/user_controller_test.exs:1: HelloWeb.UserControllerTest.__ex_unit__/2
  ...

Finished in 0.1 seconds
26 tests, 12 failures

Randomized with seed 825065
```

失敗したテストファイルのモジュール属性を編集することで、これらのテストを修正することができます。まず、`test/hello_web/controllers/user_controller_test.exs`で、`@valid_attrs`と`@update_attrs`の`:email`の値に"@"を追加します。

```elixir
defmodule HelloWeb.UserControllerTest do
  ...
  @create_attrs %{bio: "some bio", email: "some@email", name: "some name", number_of_pets: 42}
  @update_attrs %{bio: "some updated bio", email: "some updated@email", name: "some updated name", number_of_pets: 43}
  @invalid_attrs %{bio: nil, email: nil, name: nil, number_of_pets: nil}
  ...
```

これでHelloWeb.UserControllerTestの失敗をすべて修正することができるでしょう。

`test/hello/accounts/accounts_test.exs`のモジュール属性を同じように変更します。

```elixir
defmodule Hello.AccountsTest do
    ...
    @valid_attrs %{bio: "some bio", email: "some@email", name: "some name", number_of_pets: 42}
    @update_attrs %{bio: "some updated bio", email: "updated@email", name: "some updated name", number_of_pets: 43}
    @invalid_attrs %{bio: nil, email: nil, name: nil, number_of_pets: nil}
    ...
```

これにより、2つを除くすべての失敗が修正されます - 最後の2つを修正するには、テストで比較している値を修正する必要があります。

```elixir
defmodule Hello.AccountsTest do
  ...
  test "create_user/1 with valid data creates a user" do
    assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
    assert user.bio == "some bio"
    assert user.email == "some@email"
    assert user.name == "some name"
    assert user.number_of_pets == 42
  end

  ...

  test "update_user/2 with valid data updates the user" do
    user = user_fixture()
    assert {:ok, user} = Accounts.update_user(user, @update_attrs)
    assert %User{} = user
    assert user.bio == "some updated bio"
    assert user.email == "some updated@email"
    assert user.name == "some updated name"
    assert user.number_of_pets == 43
  end

end
```

これですべてのテストが再び成功しました。

```console
$ mix test
..........................

Finished in 0.2 seconds
23 tests, 0 failures

Randomized with seed 330955
```

### HTMLリソースの生成

このセクションでは、システムにPostgreSQLデータベースがインストールされていて、デフォルトのアプリケーション（EctoとPostgrexがインストールされ、自動的に設定されるもの）が生成されていることを前提に説明します。

そうではない場合は、[Ectoガイド](../ecto.html)のEctoとPostgrexの追加の項を見て、それが終わったら戻ってきてください。

OK、すべての設定が正しく行われたら、ここにある属性のリストを使って`phx.gen.html`タスクを実行する必要があります。

```console
$ mix phx.gen.html Accounts User users name:string email:string \
bio:string number_of_pets:integer
* creating lib/hello_web/controllers/user_controller.ex
* creating lib/hello_web/templates/user/edit.html.eex
* creating lib/hello_web/templates/user/form.html.eex
* creating lib/hello_web/templates/user/index.html.eex
* creating lib/hello_web/templates/user/new.html.eex
* creating lib/hello_web/templates/user/show.html.eex
* creating lib/hello_web/views/user_view.ex
* creating test/hello_web/controllers/user_controller_test.exs
* creating lib/hello/accounts/user.ex
* creating priv/repo/migrations/20180906212909_create_users.exs
* creating lib/hello/accounts.ex
* injecting lib/hello/accounts.ex
* creating test/hello/accounts/accounts_test.exs
* injecting test/hello/accounts/accounts_test.exs

Add the resource to your browser scope in web/router.ex:

    resources "/users", UserController

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

次に、タスクの指示に従って、`resources "/users", UserController` の行をルータ`lib/hello_web/router.ex`に挿入する必要があります。

```elixir
defmodule HelloWeb.Router do
  ...

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/users", UserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloWeb do
  #   pipe_through :api
  # end
end
```

それが済んだら、`ecto.create`でデータベースを作成します。

```console
$ mix ecto.create
The database for Hello.Repo has been created.
```

そして、`ecto.migrate`で`users`テーブルを作るようにデータベースをマイグレートします。

```console
$ mix ecto.migrate

[info]  == Running Hello.Repo.Migrations.CreateUser.change/0 forward

[info]  create table users

[info]  == Migrated in 0.0s
```

これで、このテストガイドを進める準備が整いました。
