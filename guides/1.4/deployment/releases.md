---
layout: 1.4/layout
version: 1.4
group: deployment
title: リリースを使ったデプロイ
nav_order: 2
hash: 5bda94164d5e0d52c740f499d4cf7fcf449d82ab
---
# リリースを使ったデプロイ

## 必要な作業

このガイドに必要なのは、動作するPhoenixアプリケーションだけです。デプロイ用の簡単なアプリケーションが必要な方は、[起動ガイド](https://hexdocs.pm/phoenix/up_and_running.html)にしたがってください。

## ゴール

このガイドの主な目的は、PhoenixアプリケーションをErlang VM、Elixir、すべてのコードと依存関係を含む自己完結型のディレクトリにパッケージ化することです。このパッケージは本番環境のマシンにドロップできます。

## リリースとアセンブル!

リリースをアセンブルするには、Elixir v1.9以降が必要です。

```console
$ elixir -v
1.9.0
```

Elixirのリリースにまだ慣れていない場合は、先に進む前に[Elixirの優れたドキュメント](https://hexdocs.pm/mix/Mix.Tasks.Release.html)を読むことをお勧めします。

これが終わったら、一般的な[デプロイメントガイド](/deployment.html)の最後に `mix release` をつけて、すべてのステップを踏んでリリースを組み立てることができます。まとめてみましょう。

まず、環境変数を設定します。

```
$ mix phx.gen.secret
REALLY_LONG_SECRET
$ export SECRET_KEY_BASE=REALLY_LONG_SECRET
$ export DATABASE_URL=ecto://USER:PASS@HOST/database
```

そして依存関係をロードしてコードとアセットをコンパイルします。

```
# Initial setup
$ mix deps.get --only prod
$ MIX_ENV=prod mix compile

# Compile assets
$ npm run deploy --prefix ./assets
$ mix phx.digest
```

そして、`mix release`を実行します。

```
$ MIX_ENV=prod mix release
Generated my_app app
* assembling my_app-0.1.0 on MIX_ENV=prod
* skipping runtime configuration (config/releases.exs not found)

Release created at _build/prod/rel/my_app!

    # To start your system
    _build/prod/rel/my_app/bin/my_app start

...
```

リリースを開始するには、`_build/prod/rel/my_app/bin/my_app start` を呼び出します（my_appは現在のアプリケーション名に置き換えてください）。そうすれば、アプリケーションは起動するはずですが、実際にはウェブサーバーが起動していないことに気づくでしょう。これは、Phoenixにウェブサーバーを起動するように指示する必要があるからです。`mix phx.server`を使っているときは、`phx.server`コマンドがそれを代行してくれますが、リリースではMix（*ビルド*ツール）がないので、自分たちでやらなければなりません。

`config/prod.secret.exs` を開くと、"Using releases" というセクションがあるはずです。その行のコメントを外すか、アプリケーション名に合わせて以下の行を手動で追加してください。

```elixir
config :my_app, MyApp.Endpoint, server: true
```

もう一度リリースを組み立てます。

```
$ MIX_ENV=prod mix release
Generated my_app app
* assembling my_app-0.1.0 on MIX_ENV=prod
* skipping runtime configuration (config/releases.exs not found)

Release created at _build/prod/rel/my_app!

    # To start your system
    _build/prod/rel/my_app/bin/my_app start
```

リリースを開始すると、ウェブサーバーも正常に起動するはずです。これで、`_build/prod/rel/my_app` ディレクトリにあるすべてのファイルを取得し、パッケージ化して、リリースを組み立てたのと同じOSとアーキテクチャを持つプロダクションマシンで実行できます。詳細は [`mix release` のドキュメント](https://hexdocs.pm/mix/Mix.Tasks.Release.html) を参照してください。

しかし、このガイドを終える前に、ほとんどのPhoenixアプリケーションが使用するであろうリリースの機能が2つあります。それらについてお話ししましょう。

## ランタイム設定

リリースをアセンブルするためには、`SECRET_KEY_BASE` と `DATABASE_URL` の両方を設定しなければならないことに気づいたかもしれません。これは、`config/config.exs`, `config/prod.exs`, およびその仲間がリリースのアセンブル時に（一般的に言えば `mix` コマンドを実行した時に）実行されるからです。

しかし、多くの場合、`SECRET_KEY_BASE` と `DATABASE_URL` の値はリリースのアセンブル時には設定せず、本番環境でシステムを起動する時にのみ設定したいです。とくに、これらの値に簡単にアクセスできない場合があり、これらの値を取得するために別のシステムにアクセスしなければならない場合があります。幸いにも、このようなユースケースのために `mix release` はランタイム設定を提供しており、3つのステップでこれを有効にできます。

1. `config/prod.secret.exs` の名前を `config/releases.exs` に変更します。

2. 新しい `config/releases.exs` ファイル内の `use Mix.Config` を `import Config` に変更します（必要であれば、`use Mix.Config` を使用している箇所をすべて `import Config` に置き換えても構いません。）

3. `config/prod.exs` を変更し、下部の `import_config "prod.secret.exs"` を呼び出さないようにします。

さて、別のリリースを組み立てるとこのようになります。

```
$ MIX_ENV=prod mix release
Generated my_app app
* assembling my_app-0.1.0 on MIX_ENV=prod
* using config/releases.exs to configure the release at runtime
```

ランタイム設定を使用していることに注目してください。これで、リリースを組み立てる際に環境変数を設定する必要がなくなり、`_build/prod/rel/my_app/bin/my_app start` とその仲間を実行するときだけ環境変数を設定するようになりました。

## Ectoマイグレーションとカスタムコマンド

また、本番環境の設定に必要なカスタムコマンドを実行することも、本番システムではよくあることです。そのようなコマンドの1つに、正確にはデータベースのマイグレーションがあります。本番環境の成果物であるリリースの中には、*ビルド*ツールである`Mix`がないので、これらのコマンドを直接リリースに持ち込む必要があります。

私たちの推奨する方法は、アプリケーション内に `lib/my_app/release.ex` のような新しいファイルを作成し、次のように記述する方法です。

```elixir
defmodule MyApp.Release do
  @app :my_app

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
```

最初の2行をアプリケーション名に置き換えてください。

これで `MIX_ENV=prod mix release` で新しいリリースを組み立て、`eval`コマンドを呼び出すことで、上のモジュールの関数を含む任意のコードを呼び出すことができます。

```
$ _build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate"
```

これでおしまいです！

## コンテナ

Elixirのリリースは、Dockerなどのコンテナ技術とうまく連携します。この考え方は、Dockerコンテナ内でリリースをアセンブルし、リリースの成果物に基づいてイメージを構築するというものです。

アプリケーションのルートで実行するDockerファイルの例を以下に示します。これはすべてのステップを含んでいます。

```dockerfile
# FROM elixir:1.9.0-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs yarn python

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

# build assets
COPY assets assets
COPY priv priv
RUN cd assets && npm install && npm run deploy
RUN mix phx.digest

# build project
COPY lib lib
RUN mix compile

# build release (uncomment COPY if rel/ exists)
# COPY rel rel
RUN mix release

# prepare release image
FROM alpine:3.9 AS app
RUN apk add --update bash openssl

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/my_app ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
```

最後に、`/app` にアプリケーションを作成し、`bin/my_app start`として実行できるようにします。
