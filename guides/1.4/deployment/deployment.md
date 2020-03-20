---
layout: default
group: deployment
title: デプロイの紹介
nav_order: 1
hash: cf93367bb60e09db056d9075adbbd05f47325052
---
# デプロイの紹介

動作するアプリケーションができたら、それをデプロイする準備ができています。独自のアプリケーションがまだ完成していない場合でも、心配しないでください。[起動ガイド](./../up_and_running.html)に従って、デプロイに使用する基本的なアプリケーションを作成してください。

アプリケーションをデプロイするための準備は、3つの主要なステップがあります:

  * アプリケーションシークレットの取り扱い
  * アセットのコンパイル
  * productionモードでのサーバーの起動

このガイドでは、ローカルに本番動作環境を構築する方法を学びます。本番でアプリケーションを動かすためにはこのガイドで説明する同じ技法を使うことができますが、デプロイインフラストラクチャによっては、追加のステップが必要となるでしょう。

他のインフラストラクチャへのデプロイへの例として、2つの異なるアプローチも言及します: 1つは[`mix release`を利用したElixirのリリース](releases.html)、もつ1つは[Herokuの利用](heroku.html)です。もしコンテナ技術でデプロイをするのがお好みなら、このリリースガイドでは利用可能なサンプルのDockerファイルも紹介します。

上記の手順を1つずつ見ていきましょう。

## アプリケーションシークレットの取り扱い

すべてのPhoenixアプリケーションは、たとえば、本番データベースのためのユーザーネームやパスワード、Phoenixが重要な情報の署名と暗号化に使用するシークレットなど、安全に保つ必要のあるデータがあります。一般的にはこれらを環境変数に保持しておいて、アプリケーションでそこから読み出すことが推奨されます。環境変数からシークレットとコンフィグを読み込む責務は、`config/prod.secret.exs`が持ちます。

したがって、関連する変数が正しく本番環境に設定されていることを確認する必要があります:

```console
$ mix phx.gen.secret
REALLY_LONG_SECRET
$ export SECRET_KEY_BASE=REALLY_LONG_SECRET
$ export DATABASE_URL=ecto://USER:PASS@HOST/database
```

これらの値をそのままコピーしてはいけません。`mix phx.gen.secret`の結果に従って、`SECRET_KEY_BASE`を設定してください。`DATABASE_URL`はデータベースアドレスに従って設定をしてください。

いくつのか理由により環境変数を使いたくない場合には、`config/prod.secret.exs`に直接、シークレットを書き込んでください。しかし、`config/prod.secret.exs`がバージョンコントロールシステムで取り扱われないように確認をしておいてください。

シークレット情報が適切で安全に設定できたので、アセットを構成してみましょう!

このステップに進む前に、少し準備が必要です。本番用にすべてを準備しているので、依存関係の解決とコンパイルをすることにより、環境のセットアップが必要です。

```console
$ mix deps.get --only prod
$ MIX_ENV=prod mix compile
```

## アセットのコンパイル

このステップは、Phoenixアプリケーション内で画像、JavaScript、スタイルシート等の静的アセットがある場合に必要となります。Phoenixの標準では、webpackを使っています。これについてこれから説明していきます。

静的アセットのコンパイルは2ステップで行います。

```console
$ npm run deploy --prefix ./assets
$ mix phx.digest
Check your digested files at "priv/static".
```

これだけです！ 最初のコマンドはアセットを構築し、2番目のコマンドはダイジェストとキャッシュマニフェストファイルを生成して、Phoenixが本番でアセットをすばやく提供できるようにします。

上記ステップの実行を忘れた場合には、Phoenixがエラーメッセージを吐き出すことを覚えておいてください:

```console
$ PORT=4001 MIX_ENV=prod mix phx.server
10:50:18.732 [info] Running MyApp.Endpoint with Cowboy on http://example.com
10:50:18.735 [error] Could not find static manifest at "my_app/_build/prod/lib/foo/priv/static/cache_manifest.json". Run "mix phx.digest" after building your static files or remove the configuration from "config/prod.exs".
```

エラーメッセージは非常に明確です。Phoenixが静的なマニフェストを見つけられなかったことを表しています。上記のコマンドを実行して修正するか、アセットを提供しないかまったく気にしない場合には、`config/prod.exs`から`cache_static_manifest`設定を削除してください。

## productionモードでのサーバーの起動

productionモードでPhoenixを開始するには、`mix phx.server`を実行する際に、`PORT`と`MIX_ENV`環境を設定しておく必要があります:

```console
$ PORT=4001 MIX_ENV=prod mix phx.server
10:59:19.136 [info] Running MyApp.Endpoint with Cowboy on http://example.com
```

デタッチモードを使うと、ターミナルを閉じたときにPhoenixサーバーを止めずに実行し続けるようになります:

```console
$ PORT=4001 MIX_ENV=prod elixir --erl "-detached" -S mix phx.server
```

エラーメッセージが表示された場合は、注意深く読んで、まだ対処方法が明確でない場合はバグレポートを確認してください。

IEx内でアプリケーションを動かすこともできます:

```console
$ PORT=4001 MIX_ENV=prod iex -S mix phx.server
10:59:19.136 [info] Running MyApp.Endpoint with Cowboy on http://example.com
```

## まとめ

前の節までは、Phoenixアプリケーションをデプロイするために必要な主要ステップを概説しました。実際には、最終的に独自のステップを追加することになります。たとえば、データベースを使用している場合、サーバーを起動する前に`mix ecto.migrate`を実行して、データベースが最新であることを確認することもできます。

全体として、ここに雛形として使用できるスクリプトを示しておきます:

```console
# Initial setup
$ mix deps.get --only prod
$ MIX_ENV=prod mix compile

# Compile assets
$ npm run deploy --prefix ./assets
$ mix phx.digest

# Custom tasks (like DB migrations)
$ MIX_ENV=prod mix ecto.migrate

# Finally run the server
$ PORT=4001 MIX_ENV=prod mix phx.server
```

以上です。次は[how to deploy Phoenix with Elixir's releases](releases.html) と [how to deploy to Heroku](heroku.html)を学ぶことができます。
