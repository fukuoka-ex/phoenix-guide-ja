---
layout: 1.5/layout
version: 1.5
group: testing
title: チャネルのテスト
nav_order: 4
hash: 4ee3484f
---
# チャネルのテスト

> **前提**: このガイドでは、入門ガイドの内容を理解し、Phoenixアプリケーションを実行していることを前提としています

> **前提**: このガイドでは[テストの導入ガイド](testing.html)を前提としています

> **前提**: このガイドでは[チャネルガイド](channels.html)を前提としています

チャネルガイドでは、"チャネル" が異なるコンポーネントを持つレイヤーシステムであることを見ました。このことを考えると、チャネル関数のユニットテストを書くだけでは十分ではない場合があるでしょう。別の不確実要素が期待通りに動作しているかどうかを検証したい場合もあるでしょう。この統合テストは、チャネルルート、チャネルモジュール、およびそのコールバックを正しく定義したこと、およびPubSubやTransportのような低レベルのレイヤーが正しく設定され、意図した通りに動作していることを保証します。

## チャネルを生成する

このガイドを進めていく中で、具体的な例があれば参考になるでしょう。Phoenixには、基本的なチャネルとテストを生成するMixタスクが付属しています。これらの生成されたファイルは、チャネルとそれに対応するテストを書く際の参考になります。それでは、チャネルを生成してみましょう。

```console
$ mix phx.gen.channel Room
* creating lib/hello_web/channels/room_channel.ex
* creating test/hello_web/channels/room_channel_test.exs

Add the channel to your `lib/hello_web/channels/user_socket.ex` handler, for example:

    channel "room:lobby", HelloWeb.RoomChannel
```

これはチャネルとそのテストを作成し、 `lib/hello_web/channels/user_socket.ex` にチャネルルートを追加するように指示します。チャネルルートを追加しないと、チャネルがまったく機能しません！

## チャネルケース

`test/hello_web/channels/room_channel_test.exs` を開くと、このようになっています。

```elixir
defmodule HelloWeb.RoomChannelTest do
  use HelloWeb.ChannelCase
```

`ConnCase` や `DataCase` と同様に、`ChannelCase` も用意されています。これら3つはすべて、Phoenixアプリケーションを起動したときに生成されたものです。これを見てみましょう。`test/support/channel_case.ex` を開きます。

```elixir
defmodule HelloWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest

      # The default endpoint for testing
      @endpoint HelloWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Demo.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Demo.Repo, {:shared, self()})
    end

    :ok
  end
end
```

これは非常に簡単です。useしたときに `Phoenix.ChannelTest` のすべてをインポートするケーステンプレートをセットアップします。`setup` ブロックでは、SQLサンドボックスを起動します。これは[コンテキストのテストガイド](testing_contexts.html)で解説しています。

## subscribeとjoin

今、私たちはPhoenixが提供しているチャネルのためのカスタムテストケースと、そのテストケースが何を提供しているかを把握したので、`test/hello_web/channels/room_channel_test.exs` の残りの部分を理解していきましょう。

まずはsetupブロックです。

```elixir
setup do
  {:ok, _, socket} =
    UserSocket
    |> socket("user_id", %{some: :assign})
    |> subscribe_and_join(RoomChannel, "room:lobby")

  %{socket: socket}
end
```

`setup` ブロックは `UserSocket` モジュールをベースにした `Phoenix.Socket` を設定します。これは "lib/hello_web/channels/user_socket.ex" にあります。その後、`UserSocket` の "room:lobby "という名前でアクセス可能な `RoomChannel` をsubscribeして参加したいと宣言しています。テストの最後に `%{socket: socket}` をメタデータとして返します。

簡単に言えば、`subscribe_and_join/3` はクライアントがチャネルに参加し、与えられたトピックにテストプロセスをサブスクライブすることをエミュレートします。これは、クライアントがそのチャネルでイベントを送受信する前にチャネルへ参加する必要があるため、必要なステップです。

## 同期応答のテスト

生成されたチャネルテストの最初のtestブロックは次のようになります。

```elixir
test "ping replies with status ok", %{socket: socket} do
  ref = push(socket, "ping", %{"hello" => "there"})
  assert_reply ref, :ok, %{"hello" => "there"}
end
```

これは、`MyAppWeb.RoomChannel` の次のコードをテストします。

```elixir
# Channels can be used in a request/response fashion
# by sending replies to requests from the client
def handle_in("ping", payload, socket) do
  {:reply, {:ok, payload}, socket}
end
```

上のコメントにあるように、`reply` はHTTPでおなじみのリクエスト/レスポンスパターンを模倣しているので、同期的であることがわかります。この同期応答は、サーバーでのメッセージの処理が終わった後にクライアントへイベントを送り返したい場合に最適です。たとえば、データベースに何かを保存して、それが終わってからクライアントにメッセージを送信する場合などです。

`test "ping replies with status ok", %{socket: socket} do` の行には、マップ `%{socket: socket}` があることがわかります。これにより、setupブロックの `socket` にアクセスできるようになります。

`push/3` でクライアントがチャネルにメッセージをプッシュする様子をエミュレートします。`ref = push(socket, "ping", %{"hello" => "there"})` で、ペイロード `%{"hello" => "there"}` を含むイベント `"ping"` をチャネルにプッシュします。これにより、チャネル内の `"ping"` イベント用の `handle_in/3` コールバックが発生します。なお、`ref` は次の行で応答をアサートするために必要になるので、`ref` を格納しておきます。`assert_reply ref, :ok, %{"hello" => "there"}` で、サーバーからの同期応答 `:ok, %{"hello" => "there"}` が送信されることをアサートします。このようにして、`"ping"` のための `handle_in/3` コールバックがトリガーされたことを確認します。

### ブロードキャストのテスト

クライアントからメッセージを受信して、現在のトピックをsubscribeしている全員にブロードキャストするのが一般的です。この一般的なパターンはPhoenixで表現するのは簡単で、`MyAppWeb.RoomChannel` で生成される `handle_in/3` コールバックの1つです。

```elixir
def handle_in("shout", payload, socket) do
  broadcast(socket, "shout", payload)
  {:noreply, socket}
end
```

その対応するテストは次のようになります。

```elixir
test "shout broadcasts to room:lobby", %{socket: socket} do
  push(socket, "shout", %{"hello" => "all"})
  assert_broadcast "shout", %{"hello" => "all"}
end
```

setupブロックと同じ `socket` にアクセスしていることに気がつきました。なんて便利なんでしょう！同期応答テストで行ったのと同じ `push/3` を行います。そこで、`%{"hello" => "all"}` というペイロードを持つ `"shout"` イベントを `push` します。

`"shout"` イベントの `handle_in/3` コールバックは同じイベントとペイロードをブロードキャストするだけなので、`"room:lobby"` にjoinしている全員がメッセージを受信するはずです。これを確認するために、`assert_broadcast "shout", %{"hello" => "all"}` を実行します。

**注意**: `assert_broadcast/3` は、メッセージがPubSubシステムでブロードキャストされたかどうかをテストします。クライアントがメッセージを受信したかどうかを調べるには `assert_push/3` を使います。

### サーバーからの非同期プッシュのテスト

`MyAppWeb.RoomChannelTest` の最後のテストでは、サーバーからのブロードキャストがクライアントにプッシュされることを確認します。これまで説明したテストとは異なり、チャネルの `handle_out/3` コールバックがトリガーされるかどうかを間接的にテストしています。この `handle_out/3` は `MyApp.RoomChannel` で次のように定義されています。

```elixir
def handle_out(event, payload, socket) do
  push(socket, event, payload)
  {:noreply, socket}
end
```

`handle_out/3` イベントはチャネルから `broadcast/3` を呼び出したときにのみ発生するので、テストではそれをエミュレートする必要があります。これをエミュレートするには、`broadcast_from` または `broadcast_from!` を使います。どちらも目的は同じですが、唯一の違いは `broadcast_from!` がブロードキャストに失敗したときにエラーを出すことです。

`broadcast_from!(socket, "broadcast", %{"some" => "data"})` は、上記の `handle_out/3` コールバックのトリガーとなり、同じイベントとペイロードをクライアントにプッシュします。これをテストするために、`assert_push "broadcast", %{"some" => "data"}` を実行します。

これで完了です。これで、リアルタイムアプリケーションを開発し、完全にテストする準備ができました。チャネルをテストする際に提供される他の機能についての詳細は、 [`Phoenix.ChannelTest`](https://hexdocs.pm/phoenix/Phoenix.ChannelTest.html) のドキュメントを参照してください。
