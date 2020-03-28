---
layout: default
group: guides
title: チャネル
nav_order: 9
hash: db21f47bded4bf91790a78887c95d16bda5ee849
---

# チャネル

チャネルは、何百万もの接続されたクライアントとの間でソフトリアルタイムなコミュニケーションを可能にする、Phoenixのエキサイティングな部分です。
いくつかのユースケースが考えられます。

- メッセージングアプリのためのチャットルームと API
- "ゴールが決まった " や "地震が来る "などの速報
- 地図上で列車、トラック、レース参加者のトラッキング
- マルチプレイヤーゲームでのイベント
- センサーのモニタリングと照明の制御
- ブラウザーへのページの CSS や JavaScript の変更の通知（開発時に便利）

概念的には、チャネルはとてもシンプルです。
クライアントは、`public_chat` や `updates:user1` のような 1 つ以上のトピックに接続してサブスクライブします。
サーバーからでもクライアントからでも、トピックで送信されたメッセージはそのトピックをサブスクライブしているすべてのクライアント（サブスクライブしている場合は送信者を含む）へ次のように送信されます。

```plaintext
                                                                  +----------------+
                                                     +--Topic X-->| Mobile Client  |
                                                     |            +----------------+
                              +-------------------+  |
+----------------+            |                   |  |            +----------------+
| Browser Client |--Topic X-->| Phoenix Server(s) |--+--Topic X-->| Desktop Client |
+----------------+            |                   |  |            +----------------+
                              +-------------------+  |
                                                     |            +----------------+
                                                     +--Topic X-->|   IoT Client   |
                                                                  +----------------+
```

チャネルは、ブラウザー、ネイティブアプリ、スマートウォッチ、組み込みデバイス、その他ネットワークに接続できるあらゆる種類のクライアントをサポートすることができます。
クライアントに必要なのは、適切なライブラリだけです。以下の[クライアントライブラリ](#client-libraries) の項を参照してください。
各クライアントライブラリは、チャネルが理解する「トランスポート」の1つを使って通信します。
現在のところ、それは Websockets かロングポーリングですが、将来的には他のトランスポートも追加されるかもしれません。

ステートレスHTTP接続とは異なり、チャネルは、軽量なBEAMプロセスに裏付けされたlong-livedな接続をサポートしており、それぞれが並行して動作し、独自の状態を維持しています。

このアーキテクチャは拡張性に優れています。Phoenix Channels は[1つのボックスで数百万人のサブスクライバーを適正なレイテンシでサポート](http://phoenixframework.org/blog/the-road-to-2-million-websocket-connections)することができ、毎秒数十万のメッセージを転送しています。
また、このキャパシティは、クラスターにノードを追加して増やすことができます。

## 動作コンポーネント

チャネルはクライアントの視点から見ると簡単に使えますが、サーバーのクラスターをまたいでクライアントにメッセージをルーティングするためには、いくつかのコンポーネントがあります。
それらを見てみましょう。

### 概要

通信を開始するには、クライアントはトランスポート（Websocketまたはロングポーリングなど）を使用してノード（Phoenixサーバー）に接続し、その単一のネットワーク接続を使用して1つ以上のチャネルに参加します。
クライアントごと、トピックごとに1つのチャネルサーバープロセスが作成されます。
適切なソケットハンドラーは、チャネルサーバー用の`%Phoenix.Socket`を初期化します（クライアントを認証した後である可能性もあります）。
その後、チャネルサーバーは `%Phoenix.Socket{}` を保持し、`socket.assigns` の中で必要な状態を維持します。

接続が確立されると、クライアントからの受信メッセージはトピックに基づいて正しいチャネルサーバーにルーティングされます。
チャネルサーバーがメッセージをブロードキャストするように要求した場合、そのメッセージはローカルのPubSubに送信され、同じサーバーに接続されていてそのトピックをサブスクライブしているすべてのクライアントに送信されます。

クラスター内に他のノードがある場合は、ローカルPubSubはそのメッセージを他ノードへのPubSubにも転送し、そのPubSubは自分のサブスクライバーにメッセージを送信します。
追加ノードごとに 1 つのメッセージを送信する必要があるだけなので、ノードを追加する際のパフォーマンスコストはごくわずかで、各新しいノードはより多くのサブスクライバーをサポートします。

メッセージの流れは次のようになります。

```plaintext
                                 Channel   +-------------------------+      +--------+
                                  route    | Sending Client, Topic 1 |      | Local  |
                              +----------->|     Channel.Server      |----->| PubSub |--+
+----------------+            |            +-------------------------+      +--------+  |
| Sending Client |-Transport--+                                                  |      |
+----------------+                         +-------------------------+           |      |
                                           | Sending Client, Topic 2 |           |      |
                                           |     Channel.Server      |           |      |
                                           +-------------------------+           |      |
                                                                                 |      |
                                           +-------------------------+           |      |
+----------------+                         | Browser Client, Topic 1 |           |      |
| Browser Client |<-------Transport--------|     Channel.Server      |<----------+      |
+----------------+                         +-------------------------+                  |
                                                                                        |
                                                                                        |
                                                                                        |
                                           +-------------------------+                  |
+----------------+                         |  Phone Client, Topic 1  |                  |
|  Phone Client  |<-------Transport--------|     Channel.Server      |<-+               |
+----------------+                         +-------------------------+  |   +--------+  |
                                                                        |   | Remote |  |
                                           +-------------------------+  +---| PubSub |<-+
+----------------+                         |  Watch Client, Topic 1  |  |   +--------+  |
|  Watch Client  |<-------Transport--------|     Channel.Server      |<-+               |
+----------------+                         +-------------------------+                  |
                                                                                        |
                                                                                        |
                                           +-------------------------+      +--------+  |
+----------------+                         |   IoT Client, Topic 1   |      | Remote |  |
|   IoT Client   |<-------Transport--------|     Channel.Server      |<-----| PubSub |<-+
+----------------+                         +-------------------------+      +--------+
```

### エンドポイント

Phoenixアプリの `Endpoint` モジュールでは、`socket` 宣言で指定した URL からの接続を受け取るソケットハンドラーを指定します。

```elixir
socket "/socket", HelloWeb.UserSocket,
  websocket: true,
  longpoll: false
```

Phoenixには、websocketとlongpollという2つのデフォルトのトランスポートが付属しています。これらは `socket` 宣言で直接設定できます。

### ソケットハンドラー

上の例の `HelloWeb.UserSocket` のようなソケットハンドラーは、Phoenixがチャネル接続をセットアップするときに呼び出されます。
指定されたURLへの接続は、エンドポイントの設定に基づいて、すべて同じソケットハンドラーを使用します。
しかし、このハンドラーは、任意の数のトピックの接続をセットアップするために使用できます。

ハンドラー内では、ソケット接続を認証して識別し、デフォルトのソケットへのassignsを設定することができます。

### チャネルルート

チャネルルートは上の例での `HelloWeb.UserSocket` のようなソケットハンドラーで定義されます。
これらはトピック文字列にマッチし、マッチしたリクエストを指定されたチャネルモジュールにディスパッチします。

星形文字 `*` はワイルドカードマッチの役割を果たすので、以下の例では `room:lobby` と `room:123` へのリクエストは両方とも `RoomChannel` にディスパッチされます。

```elixir
channel "room:*", HelloWeb.RoomChannel
```

### チャネル

チャネルはクライアントからのイベントを扱うので、コントローラーと似ていますが、2つの重要な違いがあります。チャネルのイベントは、受信と発信の両方の方向に行くことができます。チャネル接続はまた、単一のリクエスト/レスポンスサイクルを超えて持続します。チャネルは、Phoenixのリアルタイム通信コンポーネントの最高レベルの抽象化です。

各チャネルは、`join/3`、`terminate/2`、`handle_in/3`、`handle_out/3`の4つのコールバック関数のそれぞれの1つ以上を実装します。

### トピック

トピックは文字列識別子で、メッセージが適切な場所に届くようにするために、さまざまなレイヤーが使用する名前です。上で見たように、トピックはワイルドカードを使用することができます。これにより、便利な `"topic:subtopic"` の規約ができます。多くの場合、`"users:123"`のように、アプリケーションレイヤーのレコード ID を使用してトピックを作成します。

### メッセージ

`Phoenix.Socket.Message`モジュールは、以下のキーを持つ構造体を定義します。[Phoenix.Socket.Message のドキュメント](https://hexdocs.pm/phoenix/Phoenix.Socket.Message.html)より。

- `topic` 文字列トピックまたは `"messages"` や `"messages:123"` のような `"topic:subtopic"` のペアの名前空間
- `event` - 文字列のイベント名、たとえば `"phx_join"` のようなもの
- `payload` - メッセージのペイロード
- `ref` - 一意の文字列

### PubSub

通常、Phoenixアプリケーションを開発する際に、Phoenix PubSubレイヤーを直接使用することはありません。
むしろ、Phoenix自体によって内部的に使用されます。
しかし、それを設定する必要があるかもしれません。

PubSubは、`Phoenix.PubSub` モジュールと、さまざまなアダプターとその `GenServer` 用のさまざまなモジュールで構成されています。
これらのモジュールには、トピックのサブスクライブ、トピックからのサブスクライブ解除、トピックに関するメッセージのブロードキャストなど、チャネル通信を構成するための基本的な機能が含まれています。

PubSubシステムはまた、あるノードから別のノードへのメッセージを取得し、クラスター全体のすべてのサブスクライバーに送信できるようにします。
デフォルトでは、ネイティブBEAMメッセージングを使用する [Phoenix.PubSub.PG2](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.PG2.html) を使用して行われます。

デプロイ環境が分散Elixirやサーバー間の直接通信をサポートしていない場合は、PubSub データを交換するためにRedisを使用する[Redis Adapter](https://hexdocs.pm/phoenix_pubsub_redis/Phoenix.PubSub.Redis.html)も同梱されています。詳細については、[Phoenix.PubSub docs](http://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)を参照してください。

### クライアントライブラリ

クライアントライブラリがあれば、ネットワークに接続されたデバイスであれば、どのようなデバイスでもPhoenix Channelsに接続できます。
現在、以下のライブラリが存在しており、新しいライブラリはいつでも歓迎します。

#### Official

Phoenixには、新しいPhoenixプロジェクトを生成する際に使用できるJavaScriptクライアントが同梱されています。JavaScriptモジュールのドキュメントは [https://hexdocs.pm/phoenix/js/](https://hexdocs.pm/phoenix/js/) にあり、コードは [phoenix.js](https://github.com/phoenixframework/phoenix/blob/v1.4/assets/js/phoenix.js) にあります。

#### 3rd Party

- Swift (iOS)
  - [SwiftPhoenix](https://github.com/davidstump/SwiftPhoenixClient)
- Java (Android)
  - [JavaPhoenixChannels](https://github.com/eoinsha/JavaPhoenixChannels)
- C#
  - [PhoenixSharp](https://github.com/Mazyod/PhoenixSharp)
- Elixir
  - [phoenix_gen_socket_client](https://github.com/Aircloak/phoenix_gen_socket_client)
- GDScript (Godot Game Engine)
  - [GodotPhoenixChannels](https://github.com/alfredbaudisch/GodotPhoenixChannels)

## すべてを結び付ける

簡単なチャットアプリケーションを構築することで、これらのアイデアをすべて結びつけてみましょう。[起動ガイド](https://hexdocs.pm/phoenix/up_and_running.html)の後、`lib/hello_web/endpoint.ex`にエンドポイントがすでに設定されていることがわかります。

```elixir
defmodule HelloWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :hello

  socket "/socket", HelloWeb.UserSocket
  ...
end
```

`lib/hello_web/channels/user_socket.ex` では、エンドポイントで指定した `HelloWeb.UserSocket` は、アプリケーションを生成したときにすでに作成されています。メッセージが正しいチャネルへルーティングされるようにする必要があります。そのためには、 `"room:\*"` チャネルの定義のコメントを外します。

```elixir
defmodule HelloWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "room:*", HelloWeb.RoomChannel
  ...
```

これで、クライアントが `"room:"` で始まるトピックを持つメッセージを送信すると、いつでもそれがRoomChannelにルーティングされるようになります。次に、チャットルームのメッセージを管理するための `HelloWeb.RoomChannel` モジュールを定義します。

### チャネルに参加する

チャネルの最優先事項は、クライアントが指定したトピックに参加することを認可することです。認可を行うには、`lib/hello_web/channels/room_channel.ex` で `join/3` を実装しなければなりません。

```elixir
defmodule HelloWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end
  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
```

私たちのチャットアプリでは、誰でも `"room:lobby"` トピックに参加できるようにしますが、それ以外のルームはプライベートルームとみなされ、データベースからの特別な承認が必要になります。
（この演習ではプライベートなチャットルームのことは気にしませんが、終了後は自由に探索してください）

ソケットにトピックへの参加を許可するには、`{:ok, socket}` または `{:ok, reply, socket}` を返します。アクセスを拒否するには `{:error, reply}` を返します。トークンを使った認証についての詳細は、[`Phoenix.Token` documentation](https://hexdocs.pm/phoenix/Phoenix.Token.html)にあります。

チャネルを用意したので、クライアントとサーバーが話をするようにしましょう。

`mix phx.new`を実行する際に `--no-webpack` オプションで無効にしていない限り、Phoenixプロジェクトにはデフォルトで[webpack](https://webpack.js.org)が付属しています。

`assets/js/socket.js` は、Phoenixに同梱されているソケット実装をベースにしたシンプルなクライアントを定義しています。

このファイルで、ルームの名前を `"room:lobby"` に設定するだけで、このライブラリを使ってソケットに接続してチャネルに参加することができます。

```javascript
// assets/js/socket.js
// ...
socket.connect();

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel('room:lobby', {});
channel
  .join()
  .receive('ok', resp => {
    console.log('Joined successfully', resp);
  })
  .receive('error', resp => {
    console.log('Unable to join', resp);
  });

export default socket;
```

その後、`assets/js/socket.js`がアプリケーションのJavaScriptファイルにインポートされることを確認する必要があります。そのためには、`assets/js/app.js` の最後の行のコメントを外します。

```javascript
// ...
import socket from './socket';
```

ファイルを保存すると、Phoenix live reloaderのおかげでブラウザーが自動更新されるはずです。すべてがうまくいった場合、ブラウザーのJavaScriptコンソールに「Joined successfully」と表示されるはずです。クライアントとサーバーは、現在、持続的な接続を介してやり取りしています。チャットを有効にして、それを便利にしてみましょう。

`lib/hello_web/templates/page/index.html.eex` で、既存のコードをチャットメッセージを格納するコンテナと、チャットメッセージを送信するための入力フィールドに置き換えます。

```html
<div id="messages"></div>
<input id="chat-input" type="text"></input>
```

それでは、いくつかのイベントリスナーを `assets/js/socket.js` に追加してみましょう。

```javascript
// ...
let channel = socket.channel('room:lobby', {});
let chatInput = document.querySelector('#chat-input');
let messagesContainer = document.querySelector('#messages');

chatInput.addEventListener('keypress', event => {
  if (event.keyCode === 13) {
    channel.push('new_msg', { body: chatInput.value });
    chatInput.value = '';
  }
});

channel
  .join()
  .receive('ok', resp => {
    console.log('Joined successfully', resp);
  })
  .receive('error', resp => {
    console.log('Unable to join', resp);
  });

export default socket;
```

エンターキーが押されたことを検出して、メッセージ本文を含むイベントをチャネル上に `push` するだけです。イベント名は `"new_msg"` です。ここで、チャットアプリケーションのもう一つの部分、新しいメッセージをリッスンしてメッセージコンテナに追加する処理を行いましょう。

```javascript
// ...
let channel = socket.channel('room:lobby', {});
let chatInput = document.querySelector('#chat-input');
let messagesContainer = document.querySelector('#messages');

chatInput.addEventListener('keypress', event => {
  if (event.keyCode === 13) {
    channel.push('new_msg', { body: chatInput.value });
    chatInput.value = '';
  }
});

channel.on('new_msg', payload => {
  let messageItem = document.createElement('li');
  messageItem.innerText = `[${Date()}] ${payload.body}`;
  messagesContainer.appendChild(messageItem);
});

channel
  .join()
  .receive('ok', resp => {
    console.log('Joined successfully', resp);
  })
  .receive('error', resp => {
    console.log('Unable to join', resp);
  });

export default socket;
```

`channel.on` を使って `"new_msg"` イベントをリッスンし、メッセージ本文をDOMに追加します。それでは、サーバー上で受信イベントと送信イベントを処理して、図を完成させましょう。

### 受信イベント

受信イベントは `handle_in/3` で処理します。`"new_msg"` のようにイベント名をパターンマッチさせて、クライアントがチャネルを介して渡したペイロードを取得します。チャットアプリケーションでは、他の `room:lobby` のサブスクライバーに新しいメッセージを通知するために `broadcast!/3` を使います。

```elixir
defmodule HelloWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end
  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end
end
```

`broadcast!/3` は、この `socket` のトピックに参加しているすべてのクライアントに通知し、`handle_out/3` コールバックを呼び出します。`handle_out/3` は必須のコールバックではありませんが、各クライアントに届く前にブロードキャストをカスタマイズしたりフィルタリングしたりすることができます。デフォルトでは、`handle_out/3` が実装されており、定義と同じように単にメッセージをクライアントにプッシュするだけです。送信イベントにフックすることで、メッセージのカスタマイズやフィルタリングを強力に行うことができるからです。それでは、その方法を見てみましょう。

#### 発信イベントの傍受

私たちのアプリケーションには実装しませんが、チャットアプリで新しいユーザーが部屋に入ってきたメッセージを無視できるようにしたと想像してみてください。このような動作を実装するには、Phoenixにどの発信イベントを傍受したいかを明示的に伝え、それらのイベントのために `handle_out/3` コールバックを定義します（もちろん、これは `Accounts` コンテキストに `ignoring_user?/2` 関数があり、`assigns` マップを使ってユーザーを渡すことを前提としています）。重要なのは、`handle_out/3` コールバックはメッセージの受信者ごとに呼び出されることで、データベースへのアクセスのようなコストが大きい操作は `handle_out/3` に含める前に慎重に検討すべきです。

```elixir
intercept ["user_joined"]

def handle_out("user_joined", msg, socket) do
  if Accounts.ignoring_user?(socket.assigns[:user], msg.user_id) do
    {:noreply, socket}
  else
    push(socket, "user_joined", msg)
    {:noreply, socket}
  end
end
```

基本的なチャットアプリはこれだけです。複数のブラウザータブを起動すると、あなたのメッセージがすべてのウィンドウにプッシュされ、ブロードキャストされているのを見ることができます。

#### ソケットの割り当て

コネクション構造体 `%Plug.Conn{}` と同様に、チャネルソケットに値を割り当てることができます。`Phoenix.Socket.assign/3` は、`assign/3` としてチャネルモジュールに便利にインポートされています。

```elixir
socket = assign(socket, :user, msg["user"])
```

ソケットは、割り当てられた値をマップとして `socket.assigns` に格納します。

#### トークン認証の利用

接続する際には、クライアントの認証が必要になることがよくあります。幸いなことに、これは [Phoenix.Token](https://hexdocs.pm/phoenix/Phoenix.Token.html) を使った4段階のプロセスです。

**ステップ1 - コネクションでトークンを割り当てる**

アプリに `OurAuth` という認証プラグがあるとしましょう。`OurAuth`がユーザーを認証すると、`conn.assigns`のキー `:current_user` に値を設定します。`current_user` が存在するので、レイアウトで使用するためにユーザーのトークンをコネクションに割り当てることができます。この動作をプライベートな関数プラグ `put_user_token/2` でまとめることができます。これは独自のモジュールに入れることもできます。これを動作させるには、`OurAuth` と `put_user_token/2` をブラウザーのパイプラインに追加するだけです。

```elixir
pipeline :browser do
  ...
  plug OurAuth
  plug :put_user_token
end

defp put_user_token(conn, _) do
  if current_user = conn.assigns[:current_user] do
    token = Phoenix.Token.sign(conn, "user socket", current_user.id)
    assign(conn, :user_token, token)
  else
    conn
  end
end
```

これで、`conn.assigns` には `current_user` と `user_token` が含まれるようになりました。

**ステップ2 - JavaScriptにトークンを渡す**

次に、このトークンをJavaScriptに渡す必要があります。これは、app.jsスクリプトのすぐ上にある `web/templates/layout/app.html.eex` のscriptタグの中で、次のように行います。

```html
<script>window.userToken = "<%= assigns[:user_token] %>";</script>
<script src="<%= Routes.static_path(@conn, "/js/app.js") %>"></script>
```

**ステップ 3 - ソケットのコンストラクターにトークンを渡して検証する**

また、ソケットのコンストラクターに `:params` を渡し、`connect/3` 関数でユーザートークンを検証する必要があります。そのためには、`web/channels/user_socket.ex`を以下のように編集します。

```elixir
def connect(%{"token" => token}, socket, _connect_info) do
  # max_age: 1209600 is equivalent to two weeks in seconds
  case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
    {:ok, user_id} ->
      {:ok, assign(socket, :current_user, user_id)}
    {:error, reason} ->
      :error
  end
end
```

JavaScriptでは、Socketを構築する際に、先に設定したトークンを使用することができます。

```javascript
let socket = new Socket('/socket', { params: { token: window.userToken } });
```

クライアントから提供されたユーザートークンを検証するには `Phoenix.Token.verify/4` を用います。`Phoenix.Token.verify/4` は `{:ok, user_id}` か `{:error, reason}` を返します。`case`文でパターンマッチを行うことができます。トークンが検証された場合、ソケットの `:current_user` にユーザーのIDを設定します。そうでない場合は `:error` を返します。

**ステップ4 - JavaScriptでソケットに接続する**

認証を設定したことで、JavaScriptからソケットやチャネルに接続できるようになりました。

```javascript
let socket = new Socket('/socket', { params: { token: window.userToken } });
socket.connect();
```

これで繋がったので、トピックを持ってチャネルに参加することができるようになりました。

```elixir
let channel = socket.channel("topic:subtopic", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
```

トークン認証はトランスポートに依存せず、チャネルのような長期的な接続に適しているので、セッションや認証アプローチを使用するのではなく、トークン認証が望ましいことに注意してください。

## フォールトトレランスと信頼性保証

サーバーの再起動、ネットワークの切断、クライアントの接続性の低下などが発生します。堅牢なシステムを設計するためには、Phoenixがこれらのイベントにどのように対応し、どのような保証を提供しているかを理解する必要があります。

### 再接続のハンドリング

クライアントはトピックをサブスクライブし、PhoenixはそれらのサブスクライブをインメモリETSテーブルに保存します。チャネルがクラッシュした場合、クライアントは以前にサブスクライブしていたトピックに再接続する必要があります。幸いなことに、PhoenixのJavaScriptクライアントはこの方法を知っています。サーバーは、クラッシュが発生したことをすべてのクライアントに通知します。これにより、各クライアントの `Channel.onError` コールバックがトリガーされます。クライアントは、指数バックオフ（exponential back off）戦略を使ってサーバーへの再接続を試みます。再接続すると、以前にサブスクライブしていたトピックへの再接続を試みます。成功した場合は、以前と同様に、それらのトピックからのメッセージの受信を開始します。

### クライアントメッセージの再送信

チャネルクライアントは送信メッセージを `PushBuffer` にキューイングし、コネクションがあるときにサーバーに送信します。コネクションがない場合、クライアントは新しいコネクションを確立できるまでメッセージを保持します。接続がない場合、クライアントは接続を確立するまで、あるいは `timeout` イベントを受け取るまでメッセージをメモリに保持します。デフォルトのタイムアウトは5000ミリ秒に設定されています。クライアントはブラウザーのローカルストレージにメッセージを保持しないので、ブラウザータブが閉じられるとメッセージは消えてしまいます。

### サーバーメッセージの再送信

Phoenixは、クライアントにメッセージを送信する際にat-most-once戦略を使用します。クライアントがオフラインでメッセージを受信できなかった場合、Phoenixはメッセージを再送信しません。Phoenixはサーバー上にメッセージを永続化しません。サーバーが再起動すると、未送信のメッセージは消えてしまいます。アプリケーションがメッセージの配信についてより強力な保証を必要とする場合は、自分たちでそのコードを書く必要があります。一般的なアプローチとしては、サーバー上にメッセージを永続化し、クライアントが欠落しているメッセージをリクエストするという方法があります。例としては、Chris McCord氏のPhoenixのトレーニング: [クライアントコード](https://github.com/chrismccord/elixirconf_training/blob/master/web/static/js/app.js#L38-L39) と [サーバーコード](https://github.com/chrismccord/elixirconf_training/blob/master/web/channels/document_channel.ex#L13-L19) を参照してください。

### プレゼンス

Phoenixは、Phoenix.PubSubとPhoenixチャネルの上に構築されたオンラインユーザーを扱う方法を持っています。プレゼンスの使い方は、[プレゼンスガイド](presence.html)で解説しています。

#### アプリケーション例

先ほど構築したアプリケーションの例を見るには、[phoenix_chat_example](https://github.com/chrismccord/phoenix_chat_example) プロジェクトをチェックしてください。

また、[http://phoenixchat.herokuapp.com/](http://phoenixchat.herokuapp.com/) でライブデモを見ることができます。

