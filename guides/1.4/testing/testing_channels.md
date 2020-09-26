---
layout: 1.4/layout
version: 1.4
group: testing
title: "チャネルのテスト"
nav_order: 4
hash: b51f968ec1eb42a96a23dd4bf04c4efafaab8a5c
---

# チャネルのテスト

開発者として、私たちは一般的にテストを重視しています。なぜなら、テストはリグレッションを最小限に抑え、更新されたドキュメントを提供することで、アプリケーションの「将来性」を保証するのに役立つからです。Phoenixはこのことを認識しており、チャネルを含むさまざまな部分をテストするための便利な機能を提供することで、テストの記述を容易にしています。

チャネルガイドでは、「チャネル」は異なるコンポーネントを持つ層状のシステムであることを見てきました。このことを考えると、チャネル関数のための単体テストを書くだけでは十分ではない場合があるでしょう。異なる可動部分が期待通りに動作しているかどうかを検証したい場合もあるでしょう。この統合テストはチャネルルート、チャネルモジュール、およびそのコールバックを正しく定義したこと、およびPubSubやTransportのような低レベルのレイヤーが正しく設定され、意図した通りに動作していることを保証します。

#### チャネルジェネレーター

このガイドを進めていく中で、具体的な例があれば参考になるでしょう。Phoenixには、基本的なチャネルとテストを生成するMixタスクが付属しています。これらの生成されたファイルは、チャネルとそれに対応するテストを書く際の参考になります。それでは、チャネルを生成してみましょう。

```console
$ mix phx.gen.channel Room
* creating lib/hello_web/channels/room_channel.ex
* creating test/hello_web/channels/room_channel_test.exs

Add the channel to your `lib/hello_web/channels/user_socket.ex` handler, for example:

    channel "room:lobby", HelloWeb.RoomChannel
```

これはチャネルとそのテストを作成し、 `lib/hello_web/channels/user_socket.ex` にチャネルルートを追加するように指示します。チャネルルートを追加しないと、チャネルはまったく機能しません!

#### チャネルテストのヘルパーモジュール

`test/hello_web/channels/room_channel_test.exs` を調べると、`use MyAppWeb.ChannelCase` のような行があります。（注: このガイドでは、アプリの名前を `MyApp` としています。）これはどこから来ているのでしょうか？
新しいPhoenixアプリケーションを生成すると、`test/support/channel_case.ex`ファイルも生成されます。このファイルには `MyAppWeb.ChannelCase` モジュールが含まれており、チャネルの統合テストに使用します。これはチャネルのテストに便利な機能を自動的にインポートします。

ここで提供されているヘルパー関数のいくつかは、チャネル内のコールバック関数をトリガーするためのものです。その他の関数は、チャネルにのみ適用される特別なアサーションを提供してくれます。

チャネルテストでのみ使用するヘルパー関数を追加する必要がある場合は、`MyAppWeb.ChannelCase` に追加して定義し、`MyAppWeb.ChannelCase` が `use`dされるたびに `MyAppWeb.ChannelCase` がインポートされるようにします。たとえば、以下のようになります。

```elixir
defmodule MyAppWeb.ChannelCase do
  ...

  using do
    quote do
      ...
      import MyAppWeb.ChannelCase
    end
  end

  def a_channel_test_helper() do
    # code here
  end
end
```


#### setupブロック

これで、Phoenixがチャネル用のカスタムテストケースを提供していることがわかったので、`test/hello_web/channels/room_channel_test.exs`の残りの部分を理解できます。

まず最初に、setupブロックです。

```elixir
setup do
  {:ok, _, socket} =
    socket("user_id", %{some: :assign})
    |> subscribe_and_join(RoomChannel, "room:lobby")

  {:ok, socket: socket}
end
```

`setup/2` マクロはElixirに付属している `ExUnit` から提供されています。`setup/2` に渡された `do` ブロックは、それぞれのテストに対して実行されます。このとき、`{{:ok, socket: socket}`という行に注目してください。
この行は `subscribe_and_join/3` の `socket` がすべてのテストでアクセスできるようにしています。これで、作成するテストブロックごとに `subscribe_and_join/3` を呼び出す必要がなくなります。

`subscribe_and_join/3` は、クライアントがチャネルに参加し、テストプロセスを指定したトピックにサブスクライブすることをエミュレートします。クライアントがそのチャネルでイベントを送受信する前にチャネルへ参加する必要があるので、これは必要なステップです。


#### 同期応答のテスト

生成されたチャネルテストの最初のテストブロックは次のようになります。

```elixir
test "ping replies with status ok", %{socket: socket} do
  ref = push(socket, "ping", %{"hello" => "there"})
  assert_reply ref, :ok, %{"hello" => "there"}
end
```

これは、`MyAppWeb.RoomChannel`の以下のコードをテストします。

```elixir
# Channels can be used in a request/response fashion
# by sending replies to requests from the client
def handle_in("ping", payload, socket) do
  {:reply, {:ok, payload}, socket}
end
```

上のコメントにあるように、`reply`はHTTPでおなじみのリクエスト/レスポンスパターンを模倣しているので、同期的であることがわかります。この同期応答は、サーバーでのメッセージの処理が終わった後にクライアントへイベントを送り返したい場合に最適です。
たとえば、データベースに何かを保存して、それが終わってからクライアントにメッセージを送信する場合などです。

`test "ping replies with status ok", %{socket: socket} do` の行では、マップ `%{socket: socket}` があることがわかります。これにより、setupブロックの `socket` へアクセスできるようになります。

クライアントが `push/3` でチャネルにメッセージをプッシュする様子をエミュレートします。`ref = push(socket, "ping", %{"hello" => "there"})` という行で、ペイロード `%{"hello" => "there"}` を含むイベント `"ping"` をチャネルにプッシュします。これにより、チャネル内の `"ping"` イベント用の `handle_in/3` コールバックが発生します。なお、`ref` は次の行で応答をアサートするために必要になるので、`ref` を格納しておきます。`assert_reply ref, :ok, %{"hello" => "there"}` を指定すると、サーバーからの同期応答 `:ok, %{"hello" => "there"}` が送信されることをアサートします。このようにして、`"ping"` のための `handle_in/3` コールバックがトリガーされたことを確認します。


#### ブロードキャストのテスト

クライアントからメッセージを受信して、現在のトピックを購読している全員にブロードキャストするのが一般的です。この一般的なパターンはPhoenixで表現するのは簡単で、`MyAppWeb.RoomChannel`で生成される `handle_in/3` コールバックの1つです。

```elixir
def handle_in("shout", payload, socket) do
  broadcast(socket, "shout", payload)
  {:noreply, socket}
end
```

対応するテストは次のようになります。

```elixir
test "shout broadcasts to room:lobby", %{socket: socket} do
  push(socket, "shout", %{"hello" => "all"})
  assert_broadcast "shout", %{"hello" => "all"}
end
```

setupブロックと同じ `socket` にアクセスしていることに気がつきました。なんて便利なんでしょう!同期応答テストで行ったのと同じ `push/3` を行います。そこで、`%{"hello" => "all"}` というペイロードを持つ `"shout"` イベントを `push` します。

`shout"` イベントに対する `handle_in/3` コールバックは同じイベントとペイロードをブロードキャストするだけなので、`"room:lobby"` にいるすべての加入者がメッセージを受信すべきです。これを確認するには、`assert_broadcast "shout", %{"hello" => "all"}`を実行します。

**注:** `assert_broadcast/3` は、メッセージがPubSubシステムでブロードキャストされたかどうかをテストします。クライアントがメッセージを受信したかどうかを調べるには `assert_push/3` を使います。

#### サーバーからの非同期プッシュのテスト

`MyAppWeb.RoomChannelTest`の最後のテストでは、サーバーからのブロードキャストがクライアントにプッシュされることを確認します。これまで説明したテストとは異なり、チャネルの `handle_out/3` コールバックがトリガーされるかどうかを間接的にテストしています。この `handle_out/3` は `MyApp.RoomChannel` で次のように定義されています。

```elixir
def handle_out(event, payload, socket) do
  push(socket, event, payload)
  {:noreply, socket}
end
```

`handle_out/3` イベントはチャネルから `broadcast/3` を呼び出したときにのみ発生するので、テストではそれをエミュレートする必要があります。これをエミュレートするには、`broadcast_from` または `broadcast_from!`で可能です。両方とも同じ目的を果たしますが、唯一の違いは `broadcast_from!` がブロードキャストに失敗したときにエラーを発生させることです。

`broadcast_from! (socket, "broadcast", %{"some" => "data"})` 行は、上の `handle_out/3` コールバックをトリガーして、同じイベントとペイロードをクライアントにプッシュします。これをテストするために、`assert_push "broadcast", %{"some" => "data"}` を実行します。


#### まとめ

このガイドでは、`MyAppWeb.ConnCase`に付属するすべての特別なアサーションと、コールバックをトリガーしてチャネルをテストするのに役立つ関数のいくつかを扱いました。チャネルをテストするためのAPIは、Phoenix ChannelsのAPIとほぼ一致しているので、作業が簡単になります。

`MyAppWeb.ChannelCase` が提供するヘルパーについて詳しく知りたい方は、これらの関数を定義するモジュールである [`Phoenix.ChannelTest`](https://hexdocs.pm/phoenix/Phoenix.ChannelTest.html) のドキュメントを参照してください。
