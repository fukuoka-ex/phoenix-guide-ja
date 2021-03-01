---
layout: 1.5/layout
version: 1.5
group: guides
title: Telemetry
nav_order: 10
hash: bb88c55c
---
# Telemetry

このガイドでは、Phoenixアプリケーションで `:telemetry` イベントを計測してレポートする方法を紹介します。

> `te·lem·e·try` - 機器の測定値を記録および送信するプロセス

このガイドに沿って進んでいくうちに、Telemetryのコアコンセプトを紹介し、アプリケーションのイベントをキャプチャするためのレポーターを初期化し、`:telemetry` を使って自分の関数を適切に計測するためのステップを紹介していきます。Telemetryがアプリケーションでどのように機能するかを詳しく見てみましょう。

## 概要

ライブラリ `[:telemetry]` は、アプリケーションのライフサイクルのさまざまな段階でイベントを放出することを可能にします。これらのイベントに応答するには、とくに、それらをメトリクスとして集約し、メトリクスデータをレポート先に送信できます。

Telemetryは、各イベントのハンドラーと一緒に、その名前でイベントをETSテーブルに保存します。そして、与えられたイベントが実行されると、Telemetryはそのハンドラーを探し出し、それを呼び出します。

PhoenixのTelemetryツールは、`Telemetry.Metrics` を使用して、扱うTelemetryイベントのリストと、それらのイベントをどのように扱うか、つまり、特定のタイプのメトリックとしてどのように構成するかを定義するスーパーバイザーを提供します。このスーパーバイザーはTelemetryレポーターと協力して、指定されたTelemetryイベントを適切なメトリックとして集約し、正しい報告先に送信することで応答します。

## Telemetryスーパーバイザー

v1.5以降、新しいPhoenixアプリケーションは、Telemetryスーパーバイザーとともに生成されます。このモジュールは、Telemetryプロセスのライフサイクルを管理します。また、`metrics/0` 関数を定義しており、アプリケーション用に定義した [`Telemetry.Metrics`](https://hexdocs.pm/telemetry_metrics) のリストを返します。 デフォルトでは、スーパーバイザーは [`:telemetry_poller`](http://hexdocs.pm/telemetry_poller) も起動します。依存関係として `:telemetry_poller` を追加するだけで、指定した間隔でVM関連のイベントを受け取ることができます。 古いバージョンのPhoenixを使っている場合は、`:telemetry_metrics` と `:telemetry_poller` パッケージをインストールしてください。


```elixir
{:telemetry_metrics, "~> 0.4"},
{:telemetry_poller, "~> 0.4"}
```

そして `lib/my_app_web/telemetry.ex` でTelemetryスーパーバイザーを作成します。

```elixir
# lib/my_app_web/telemetry.ex
defmodule MyAppWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {MyApp, :count_users, []}
    ]
  end
end
```

MyAppは必ず実際のアプリケーション名に置き換えてください。

その後、メインアプリケーションのスーパーバイザーツリーに追加します。
(通常は `lib/my_app/application.ex`) にあります。

```elixir
children = [
  MyApp.Repo,
  MyAppWeb.Telemetry,
  MyAppWeb.Endpoint,
  ...
]
```

## Telemetryイベント

多くのElixirライブラリ（Phoenixを含む）は、アプリケーションのライフサイクルの重要な瞬間にイベントを発行することで、ユーザーがアプリケーションの動作をより深く理解できるようにする方法として、[`:telemetry`](http://hexdocs.pm/telemetry)パッケージをすでに使用しています。

Telemetryイベントは以下のもので構成されています。

  * `name` - 文字列 (例: `"my_app.worker.stop"`) または、イベントを一意に識別するアトムのリスト

  * `measurements` - アトムキー(例: `:duration`)と数値のマップ

  * `metadata` - メトリクスのタグ付けに使用できるキーと値のペアのマップ



### Phoenixの例

エンドポイントからのイベントの例を示します。

* `[:phoenix, :endpoint, :stop]` - エンドポイントのデフォルトプラグの1つである `Plug.Telemetry` によって、レスポンスが送信されるたびにディスパッチされます

  * Measurement: `%{duration: native_time}`

  * Metadata: `%{conn: Plug.Conn.t}`


これは、各リクエストの後に `Plug` が `:telemetry` 経由で "stop" イベントを発生させ、レスポンスを得るまでにかかった時間を計測することを意味します。

```elixir
:telemetry.execute([:phoenix, :endpoint, :stop], %{duration: duration}, %{conn: conn})
```

### Phoenix Telemetryイベント

PhoenixのすべてのTelemetryイベントの完全なリストは `Phoenix.Logger` にあります。

## メトリクス

> メトリクスは、Telemetryイベントの集合体です。メトリクスは、特定の名前を持つTelemetryイベントの集合体であり、システムの動作のビューを提供します。
> &#x2015; `Telemetry.Metrics`

Telemetry.Metricsパッケージは、メトリクスを定義するための共通のインターフェイスを提供します。これは、与えられたTelemetryイベントを特定の測定として構造化する役割を担う [5つのメトリック型関数](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html#module-metrics) のセットを公開しています。

このパッケージは、測定値自体の集計を行いません。代わりに、レポーターにTelemetry event-as-measurementsの定義を提供し、レポーターはその定義を使用して集計を実行し、それらをレポートします。

レポーターについては、次のセクションで説明します。 いくつかの例を見てみましょう。`Telemetry.Metrics` を使って、HTTPリクエストが何回完了したかをカウントするカウンタメトリックを定義できます。

```elixir
Telemetry.Metrics.counter("phoenix.endpoint.stop.duration")
```

また、特定の時間帯のバケットでどれだけのリクエストが完了したかを見るために、distributionメトリックを使うこともできます。

```elixir
Telemetry.Metrics.distribution("phoenix.endpoint.stop.duration", buckets: [100, 200, 300])
```

HTTPリクエストをイントロスペクトするこの機能は本当に強力です -- これはPhoenixフレームワークが発する _多くの_ telemetryイベントの1つに過ぎません！これらのイベントの詳細と、Phoenix/Plugイベントから貴重なデータを抽出するための特定のパターンについては、このガイドの後の [Phoenix Metrics](#phoenix-metrics) のセクションで説明します。

 > Phoenixから放出される `:telemetry` イベントの完全なリストと、その測定値とメタデータは、`Phoenix.Logger` モジュールのドキュメントの "Instrumentation" セクションにあります。



### Ectoの例

Phoenixと同様に、EctoにはTelemetryイベントが組み込まれています。これは、同じツールを使ってWebやデータベース層の内観を得ることができることを意味します。 ここでは、Ectoリポジトリの起動時にEctoによって実行されるTelemetryイベントの例を示します。

* `[:ecto, :repo, :init]` - `Ecto.Repo.Supervisor` によってディスパッチされます
  * Measurement: `%{system_time: native_time}`
  * Metadata: `%{repo: Ecto.Repo, opts: Keyword.t()}`  

これは、`Ecto.Repo.Supervisor` が起動するたびに、`:telemetry` を介して起動時の時間を計測したイベントを発することを意味します。

```elixir
:telemetry.execute([:ecto, :repo, :init], %{system_time: System.system_time()}, %{repo: repo, opts: opts})
```

追加のTelemetryイベントは、Ectoアダプターによって実行されます。

このようなアダプター固有のイベントのひとつに `[:my_app, :repo, :query]` イベントがあります。
たとえば、クエリの実行時間をグラフ化したい場合は、`Telemetry.Metrics.summary/2` 関数を使って `[:my_app, :repo, :query]` イベントの最大値、平均値、パーセンタイルなどの統計情報を計算するようにレポーターに指示できます。

```elixir
Telemetry.Metrics.summary("my_app.repo.query.query_time",
  unit: {:native, :millisecond}
)
```

あるいは、`Telemetry.Metrics.distribution/2` 関数を使用して、別のアダプター固有のイベントのヒストグラムを定義することもできます。このようにして、クエリがキューに入れられている時間を可視化できます。

```elixir
Telemetry.Metrics.distribution("my_app.repo.query.queue_time",
  unit: {:native, :millisecond},
  buckets: [10, 50, 100]
)
```
> [`Ecto.Repo`](https://hexdocs.pm/ecto/Ecto.Repo.html)モジュールのドキュメントの「Telemetry Events」のセクションで、Ecto Telemetryについての詳細を知ることができます。
 
ここまでで、Phoenixアプリケーションに共通するTelemetryイベントのいくつかを、さまざまな測定値やメタデータの例とともに見てきました。これらのデータが消費されるのを待っている間に、レポーターについて話をしましょう。


## レポーター

レポーターは、`Telemetry.Metrics` で提供される共通のインターフェイスを使ってTelemetryイベントをsubscribeします。そして、測定値（データ）をメトリクスに集約し、アプリケーションに関する意味のある情報を提供します。 たとえば、次の `Telemetry.Metrics.summary/2` 呼び出しがTelemetryスーパーバイザーの `metrics/0` 関数に追加されたとします。

```elixir
summary("phoenix.endpoint.stop.duration",
  unit: {:native, :millisecond}
)
```

その後、レポーターは `"phoenix.endpoint.stop.duration"` イベントのリスナーをアタッチし、与えられたイベントメタデータでサマリーメトリックを計算して適切なソースにそのメトリックをレポートすることでこのイベントに応答します。




### Phoenix.LiveDashboard

Telemetryメトリクスのリアルタイムビジュアライゼーションに興味がある開発者は、 [`LiveDashboard`](https://hexdocs.pm/phoenix_live_dashboard) をインストールすることに興味があるかもしれません。LiveDashboardはTelemetry.Metricsのレポーターとして機能し、ダッシュボード上にリアルタイムで美しいチャートとしてデータを表示します。 

### Telemetry.Metrics.ConsoleReporter

`Telemetry.Metrics` には `ConsoleReporter` が同梱されています。このレポーターを使って、このガイドで説明されているメトリクスを試すことができます。 Telemetryのスーパーバイザーツリー（通常は `lib/my_app_web/telemetry.ex` にあります）の子リストに、以下の項目をアンコメントするか、追加してください。


```elixir
{Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
```

> StatsDやPrometheusなどのサービスでは、多数のレポーターが利用可能です。[hex.pm](https://hex.pm/packages?search=telemetry_metrics)で "telemetry_metrics" と検索すると出てきます。

## Phoenixメトリクス

先ほど、`Plug.Telemetry` が発する "stop" イベントを見て、HTTPリクエストの数をカウントするのに使いました。実際には、リクエストの総数だけを見ることができるのはある程度便利なだけです。ルートごと、あるいはルート _と_ メソッドごとのリクエスト数を見たい場合はどうでしょうか？

HTTPリクエストのライフサイクル中に発生する別のイベントを見てみましょう。今回は `Phoenix.Router` です。

* `[:phoenix, :router_dispatch, :stop]` - 一致したルートへのディスパッチに成功した後、Phoenix.Router によってディスパッチされます
* Measurement: `%{duration: native_time}`
* Metadata: `%{conn: Plug.Conn.t, route: binary, plug: module, plug_opts: term, path_params: map, pipe_through: [atom]}` 

これらのイベントをルートごとにグループ化することから始めましょう。Telemetryスーパーバイザーの `metrics/0` 関数（通常は `lib/my_app_web/telemetry.ex` にあります）に以下を追加します（まだ存在していなければ）。

```elixir
# lib/my_app_web/telemetry.ex
def metrics do
  [
    ...metrics...
    summary("phoenix.router_dispatch.stop.duration",
      tags: [:route],
      unit: {:native, :millisecond}
    )
  ]
end
```

サーバーを再起動してから、1～2ページにリクエストを出してください。ターミナルでは、提供したメトリクス定義の結果として受け取ったTelemetryイベントのログをConsoleReporterがprintしているのを見ることができるはずです。

各リクエストのログ行には、そのリクエストの特定のルートが含まれています。これは、サマリーメトリックに `:tags` オプションを指定したことによるもので、`tags` によってルートごとにメトリクスをグループ化でき、最初の要件を満たしています。レポーターは、使用している基礎となるサービスに応じて、必然的にタグの扱いが異なることに注意してください。

ルータの "stop" イベントをよく見ると、リクエストを表す `Plug.Conn` 構造体がメタデータに存在することがわかりますが、`conn` のプロパティにはどうやってアクセスするのでしょうか？幸いなことに、`Telemetry.Metrics` は、イベントを分類するのに役立つ次のオプションを提供しています。 

* `:tag` - グループ化するためのメタデータキーのリスト
* `:tag_values` - メタデータを目的のフォーマットに変換する関数です。この関数はイベントごとに呼び出されるので、イベントの発生率が高い場合は高速に処理することが重要です。

> すべての利用可能なメトリクスオプションについて `Telemetry.Metrics` モジュールのドキュメントを参照ください。

メタデータに `conn` を含むイベントから、より多くのタグを抽出する方法を見てみましょう。

### Plug.Connからtag valueを抽出する

ルートイベントに別のメトリックを追加し、今回はルートとメソッドでグループ化してみましょう。
```elixir
summary("phoenix.router_dispatch.stop.duration",
  tags: [:method, :route],
  tag_values: &get_and_put_http_method/1,
  unit: {:native, :millisecond}
)
```

必要な値を得るためにはイベントのメタデータに変換を行う必要があるため、ここでは `:tag_values` オプションを導入しました。次のプライベート関数をTelemetryモジュールに追加して、`Plug.Conn` 構造体から `:method` の値を持ち出すようにします。

```elixir
# lib/my_app_web/telemetry.ex
defp get_and_put_http_method(%{conn: %{method: method}} = metadata) do
  Map.put(metadata, :method, method)
end
```

サーバーを再起動して、さらにリクエストを行います。HTTPメソッドとルートの両方にタグが付いたログが表示されるようになるはずです。オプション `:tags` と `:tag_values` は、すべての `Telemetry.Metrics` タイプに適用できることに注意してください。

### tag valueを使ってラベルを変更する

メトリックを表示する際に、読みやすさを向上させるために値のラベルを変換する必要がある場合があります。たとえば、次のメトリックは、各LiveViewの `mount/3` コールバックの持続時間を `connected?` ステータスを利用して表示します。



```elixir
summary("phoenix.live_view.mount.stop.duration",
  unit: {:native, :millisecond},
  tags: [:view, :connected?],
  tag_values: &live_view_metric_tag_values/1
)
```

次の関数は、前の例と同様に `metadata.socket.view` と `metadata.socket.connected?` を `metadata` のtop-levelキーにします。

```elixir
# lib/my_app_web/telemetry.ex
defp live_view_metric_tag_values(metadata) do
  metadata
  |> Map.put(:view, metadata.socket.view)
  |> Map.put(:connected?, metadata.socket.connected?)
end
```

しかし、これらのメトリクスをLiveDashboardでレンダリングすると、値のラベルは `"Elixir.Phoenix.LiveDashboard.MetricsLive true"` として出力されます。

値のラベルを読みやすくするために、プライベート関数を更新して、よりユーザーフレンドリーな名前を生成できます。ここでは、`:view` の値を `inspect/1` で実行して `Elixir.` 接頭辞を削除し、別のプライベート関数を呼び出して `connected?` ブール値を人間が読めるテキストに変換します。

```elixir
# lib/my_app_web/telemetry.ex
defp live_view_metric_tag_values(metadata) do
  metadata
  |> Map.put(:view, inspect(metadata.socket.view))
  |> Map.put(:connected?, get_connection_status(metadata.socket))
end

defp get_connection_status(%{connected?: true}), do: "Connected"
defp get_connection_status(%{connected?: false}), do: "Disconnected"
```

これで `:tag_values` オプションの使い方のヒントが得られたと思います。この関数はイベントごとに呼び出されるので、高速にしておくことを覚えておいてください。

## 定期的な測定

アプリケーション内のキー値を定期的に測定したいと思うかもしれません。幸いなことに、[`:telemetry_poller`](http://hexdocs.pm/telemetry_poller) パッケージはカスタム測定のためのメカニズムを提供しており、プロセス情報を取得したり、カスタム測定を定期的に実行したりするのに便利です。

Telemetryスーパーバイザーの `periodic_measurements/0` 関数のリストに以下を追加してください。これは、指定した間隔で測定する測定値のリストを返すプライベート関数です。

```elixir
# lib/my_app_web/telemetry.ex
defp periodic_measurements do
  [
    {MyApp, :measure_users, []},
    {:process_info,
      event: [:my_app, :my_server],
      name: MyApp.MyServer,
      keys: [:message_queue_len, :memory]}
  ]
end
```

ここで、`MyApp.measure_users/0` は次のように書くことができます。

```elixir
# lib/my_app.ex
defmodule MyApp do
  def measure_users do
    :telemetry.execute([:my_app, :users], %{total: MyApp.users_count()}, %{})
  end
end
```

これで、測定値が配置された状態で、上記のイベントのメトリクスを定義することができるようになりました。
```elixir
# lib/my_app_web/telemetry.ex
def metrics do
  [
    ...metrics...
    # MyApp Metrics
    last_value("my_app.users.total"),
    last_value("my_app.my_server.memory", unit: :byte),
    last_value("my_app.my_server.message_queue_len")
    summary("my_app.my_server.call.stop.duration"),
    counter("my_app.my_server.call.exception")
  ]
end
```

> [カスタムイベント](#custom-events)セクションでMyApp.MyServerを実装します。

## Telemetryを使用したライブラリ

Telemetryは、Elixirのパッケージ計測のデファクトスタンダードになりつつあります。現在 `:telemetry` イベントを発行しているライブラリのリストを以下に示します。

ライブラリの作者は、自分のライブラリを追加してPRを送ることを積極的に奨励しています（アルファベット順でお願いします）


* [Absinthe](https://hexdocs.pm/absinthe) - Coming Soon!
* [Broadway](https://hexdocs.pm/broadway) - [Events](https://hexdocs.pm/broadway/Broadway.html#module-telemetry)
* [Ecto](https://hexdocs.pm/ecto) - [Events](https://hexdocs.pm/ecto/Ecto.Repo.html#module-telemetry-events)
* [Oban](https://hexdocs.pm/oban) - [Events](https://hexdocs.pm/oban/Oban.Telemetry.html)
* [Phoenix](https://hexdocs.pm/phoenix) - [Events](https://hexdocs.pm/phoenix/Phoenix.Logger.html#module-instrumentation)
* [Plug](https://hexdocs.pm/plug) - [Events](https://hexdocs.pm/plug/Plug.Telemetry.html)
* [Tesla](https://hexdocs.pm/tesla) - [Events](https://hexdocs.pm/tesla/Tesla.Middleware.Telemetry.html)

## カスタムイベント

アプリケーションにカスタムメトリクスや計測器が必要な場合は、お気に入りのフレームワークやライブラリと同じように `:telemetry` パッケージ（https://hexdocs.pm/telemetry）を利用できます。

ここでは、Telemetryイベントを発するシンプルなGenServerの例を示します。このファイルをアプリ内の `lib/my_app/my_server.ex` に作成します。

```elixir
# lib/my_app/my_server.ex
defmodule MyApp.MyServer do
  @moduledoc """
  An example GenServer that runs arbitrary functions and emits telemetry events when called.
  """
  use GenServer

  # A common prefix for :telemetry events
  @prefix [:my_app, :my_server, :call]

  def start_link(fun) do
    GenServer.start_link(__MODULE__, fun, name: __MODULE__)
  end

  @doc """
  Runs the function contained within this server.

  ## Events

  The following events may be emitted:

    * `[:my_app, :my_server, :call, :start]` - Dispatched
      immediately before invoking the function. This event
      is always emitted.

      * Measurement: `%{system_time: system_time}`

      * Metadata: `%{}`

    * `[:my_app, :my_server, :call, :stop]` - Dispatched
      immediately after successfully invoking the function.

      * Measurement: `%{duration: native_time}`

      * Metadata: `%{}`

    * `[:my_app, :my_server, :call, :exception]` - Dispatched
      immediately after invoking the function, in the event
      the function throws or raises.

      * Measurement: `%{duration: native_time}`

      * Metadata: `%{kind: kind, reason: reason, stacktrace: stacktrace}`
  """
  def call!, do: GenServer.call(__MODULE__, :called)

  @impl true
  def init(fun) when is_function(fun, 0), do: {:ok, fun}

  @impl true
  def handle_call(:called, _from, fun) do
    # Wrap the function invocation in a "span"
    result = telemetry_span(fun)

    {:reply, result, fun}
  end

  # Emits telemetry events related to invoking the function
  defp telemetry_span(fun) do
    start_time = emit_start()

    try do
      fun.()
    catch
      kind, reason ->
        stacktrace = System.stacktrace()
        duration = System.monotonic_time() - start_time
        emit_exception(duration, kind, reason, stacktrace)
        :erlang.raise(kind, reason, stacktrace)
    else
      result ->
        duration = System.monotonic_time() - start_time
        emit_stop(duration)
        result
    end
  end

  defp emit_start do
    start_time_mono = System.monotonic_time()

    :telemetry.execute(
      @prefix ++ [:start],
      %{system_time: System.system_time()},
      %{}
    )

    start_time_mono
  end

  defp emit_stop(duration) do
    :telemetry.execute(
      @prefix ++ [:stop],
      %{duration: duration},
      %{}
    )
  end

  defp emit_exception(duration, kind, reason, stacktrace) do
    :telemetry.execute(
      @prefix ++ [:exception],
      %{duration: duration},
      %{
        kind: kind,
        reason: reason,
        stacktrace: stacktrace
      }
    )
  end
end
```

これをアプリケーションのスーパーバイザーツリー（通常は `lib/my_app/application.ex`）に追加し、呼び出されたときに呼び出される関数を与えます。

```elixir
# lib/my_app/application.ex
children = [
  # Start a server that greets the world
  {MyApp.MyServer, fn -> "Hello, world!" end},
]
```

ここでIExセッションを開始し、サーバーを呼び出します。

```elixir
iex(1)> MyApp.MyServer.call!
```

すると、次のような出力が表示されるはずです。

```elixir
[Telemetry.Metrics.ConsoleReporter] Got new event!
Event name: my_app.my_server.call.stop
All measurements: %{duration: 4000}
All metadata: %{}

Metric measurement: #Function<2.111777250/1 in Telemetry.Metrics.maybe_convert_measurement/2> (summary)
With value: 0.004 millisecond
Tag values: %{}

"Hello, world!"
```
