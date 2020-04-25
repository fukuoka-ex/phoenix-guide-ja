---
layout: 1.4/layout
version: 1.4
group: guides
title: プレゼンス
nav_order: 9
hash: 0c5544ed9f769e03cc0b2d43ebf4d22ee52cd029
---

# プレゼンス

Phoenixプレゼンスは、トピックのプロセス情報を登録し、クラスター間で透過的に複製することができる機能です。サーバーサイドとクライアントサイドの両方のライブラリを組み合わせたもので、実装が簡単です。簡単な使用例としては、アプリケーションで現在オンラインになっているユーザーを表示することが挙げられます。 

Phoenixプレゼンスが特別なのには、いくつかの理由があります。単一障害点がなく、信頼できる唯一の情報源（SSOT）がなく、運用上の依存関係がなく、標準ライブラリに完全に依存しており、自己修復を行います。これらはすべてコンフリクトフリーなレプリケートデータ型（CRDT）プロトコルで処理されます。 

プレゼンスを使い始めるには、まずプレゼンスモジュールを生成する必要があります。これは `mix phx.gen.presence` タスクで行うことができます。 

```console
$ mix phx.gen.presence
* creating lib/hello_web/channels/presence.ex

Add your new module to your supervision tree,
in lib/hello/application.ex:

    children = [
      ...
      HelloWeb.Presence,
    ]

You're all set! See the Phoenix.Presence docs for more details:
http://hexdocs.pm/phoenix/Phoenix.Presence.html
```

`lib/hello_web/channels/presence.ex` ファイルを開くと、以下のような行が表示されます。

```elixir
use Phoenix.Presence, otp_app: :hello,
                      pubsub_server: Hello.PubSub
```

これはプレゼンスのためのモジュールをセットアップし、プレゼンスを追跡するために必要な関数を定義します。ジェネレータータスクで述べたように、このモジュールを`application.ex`にある監視ツリーに追加する必要があります。

```elixir
children = [
  ...
  HelloWeb.Presence,
]
```

次に、プレゼンスが通信できるチャネルを作成します。この例では `RoomChannel` [詳細はチャネルガイドを参照](channels.html)）を作成します。

```console
$ mix phx.gen.channel Room
* creating lib/hello_web/channels/room_channel.ex
* creating test/hello_web/channels/room_channel_test.exs

Add the channel to your `lib/hello_web/channels/user_socket.ex` handler, for example:

    channel "room:lobby", HelloWeb.RoomChannel
```

そして、`lib/hello_web/channels/user_socket.ex` に登録します。

```elixir
defmodule HelloWeb.UserSocket do
  use Phoenix.Socket

  channel "room:lobby", HelloWeb.RoomChannel
end
```

また、connect関数を変更してパラメーターから `user_id` を受け取り、ソケットに割り当てる必要があります。本番環境では、認証済みのユーザーがいる場合は `Phoenix.Token` を使いたいかもしれません。

```elixir
def connect(params, socket, _connect_info) do
  {:ok, assign(socket, :user_id, params["user_id"])}
end
```

次に、プレゼンスを通信するチャネルを作成します。ユーザーが参加した後、プレゼンスのリストをチャネルにプッシュして、コネクションを追跡することができます。また、追跡する追加情報のマップを提供することもできます。

クライアントを一意に識別するために、コネクションから `user_id` を提供することに注意してください。識別子は任意のものを使うことができますが、以下のクライアント側の例でソケットにどのように提供されるかを見てみましょう。

チャネルについての詳細は、[チャネルガイド](channels.html)を参照してください。


```elixir
defmodule HelloWeb.RoomChannel do
  use Phoenix.Channel
  alias HelloWeb.Presence

  def join("room:lobby", _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second))
    })
    {:noreply, socket}
  end
end
```

最後に、`phoenix.js`に含まれるクライアント側プレゼンスライブラリを利用して、ソケットを経由してくる状態とプレゼンスの差分を管理することができます。このライブラリは `"presence_state"` と `"presence_diff"` イベントをリッスンし、`onSync` コールバックでイベントを処理するためのシンプルなコールバックを提供します。

`onSync` コールバックを使うとプレゼンスの状態変化に簡単に反応することができます。これは、多くの場合、アクティブなユーザーのリストを更新して再表示することになります。`list` メソッドを使うと、アプリケーションのニーズに基づいて個々のプレゼンスをフォーマットして返すことができます。

ユーザーを反復処理するには、コールバックを受け付ける `presences.list()` 関数を使います。コールバックは各プレゼンスに対して2つの引数、プレゼンスIDとメタのリスト(そのプレゼンスIDに対応するプレゼンスごとに1つずつ)を指定して呼び出されます。これを使ってユーザーとオンラインになっているデバイスの数を表示します。

以下を `assets/js/app.js` に追加することで、プレゼンスが動作していることを確認できます。

```javascript
import {Socket, Presence} from "phoenix"

let socket = new Socket("/socket", {
  params: {user_id: window.location.search.split("=")[1]}
})

let channel = socket.channel("room:lobby", {})
let presence = new Presence(channel)

function renderOnlineUsers(presence) {
  let response = ""

  presence.list((id, {metas: [first, ...rest]}) => {
    let count = rest.length + 1
    response += `<br>${id} (count: ${count})</br>`
  })

  document.querySelector("main[role=main]").innerHTML = response
}

socket.connect()

presence.onSync(() => renderOnlineUsers(presence))

channel.join()
```

3つのブラウザータブを開くことで、これが動作していることを確認できます。2つのブラウザータブで http://localhost:4000/?name=Alice に移動し、 http://localhost:4000/?name=Bob に移動すると、以下のように表示されるはずです。 

```plaintext
Alice (count: 2)
Bob (count: 1)
```

アリスタブの1つを閉じればカウントは1に減り、別のタブを閉じればリストから完全に消えるはずです。
