---
layout: 1.5/layout
version: 1.5
group: deployment
title: Gigalixirへのデプロイ
nav_order: 3
hash: d8f2f90f
---
# Gigalixirへのデプロイ

## 必要なもの

このガイドに必要なのは、動作するPhoenixアプリケーションだけです。デプロイ用の簡単なアプリケーションが必要な方は、[起動ガイド](../introduction/up_and_running.html)にしたがってください。

## ゴール

このガイドの主な目的は、Gigalixir上でPhoenixアプリケーションを実行することです。

## 手順

現在地を確認できるように、手順をいくつかのステップに分けておきます。

- Gitリポジトリの初期化
- Gigalixir CLIのインストール
- Gigalixirのサインアップ
- Gigalixirアプリの作成とセットアップ
- データベースの用意
- プロジェクトをGigalixirに対応させる
- デプロイ!
- 便利なGigalixirコマンド

## Gitリポジトリの初期化

Gitリポジトリの初期化がまだなら、ファイルをgitにコミットする必要がある。プロジェクトディレクトリにて下記のコマンドを実行するとGitリポジトリの初期化ができます:

```console
$ git init
$ git add .
$ git commit -m "Initial commit"
```

## Gigalixir CLIのインストール

[ここ](https://gigalixir.readthedocs.io/en/latest/getting-started-guide.html#install-the-command-line-interface)の説明にしたがって、お使いの環境にあうCLI(コマンドラインインターフェース)をインストールしてください。

## Gigalixirのサインアップ

[gigalixir.com](https://www.gigalixir.com)もしくはCLIでアカウントのサインアップができます。CLIを使って進めましょう。

```console
$ gigalixir signup
```

Gigalixirのフリープランはクレジットカードは必要ではなく、無料で1つのアプリインスタンスと1つのpostgresqlデータベースを使うことができます。しかし、本番運用するつもりなら有料プランにアップグレードすることを検討してください。

次にログインしてみましょう。

```console
$ gigalixir login
```

そして確かめてみましょう。

```console
$ gigalixir account
```

## Gigalixirアプリの作成とセットアップ

GigalixirでPhoenixアプリをデプロイする方法は3つあります: ひとつはmix、もう一つはElixir releases、3つ目はDistilleryです。このガイドでは、mixを使うことにします。なぜなら一番簡単に起動できて稼働できるからです。しかしリモートオブザーバーを接続したりホットアップグレードはできません。もっと詳しい情報は[Mix、Distillery、Elixir Releasesの比較](https://gigalixir.readthedocs.io/en/latest/modify-app/index.html#mix-vs-distillery-vs-elixir-releases)を参照してください。他の方法でデプロイしたいなら、[スタートガイド](https://gigalixir.readthedocs.io/en/latest/getting-started-guide.html)に従ってください。

### Gigalixirアプリの作成

Gigalixirアプリを作ってみましょう。

```console
$ gigalixir create
```

作られたことを確かめてみましょう。

```console
$ gigalixir apps
```

git remoteが作られたことを確かめてみましょう。

```console
$ git remote -v
```

### バージョン指定

Elixir、Erlang、Node.jsのバージョンがデフォルトで使えるビルドパックではかなり古いので、開発に使ったバージョンと本番のバージョンをそろえておくことはよい考えです。それではこれをやっておきましょう。

```console
$ echo "elixir_version=1.10.3" > elixir_buildpack.config
$ echo "erlang_version=22.3" >> elixir_buildpack.config
$ echo "node_version=12.16.3" > phoenix_static_buildpack.config
```

コミットすることを忘れないでください。

```console
$ git add elixir_buildpack.config phoenix_static_buildpack.config
$ git commit -m "set elixir, erlang, and node version"
```
## プロジェクトをGigalixirに対応させる

Giglaixirでアプリを稼働させるために必要な作業はもうないが、おそらくSSLを強制したいかもしれない。そのためには[SSL強制](../howto/using_ssl.html#force-ssl)を参照してくだい。

またデータベース接続でSSLを使いたいかもしれない。このためには、`Repo`コンフィグの中で`ssl: true`のコメントアウトを外してください。

## データベースの用意

アプリのためにデータベースを用意しましょう。

```console
$ gigalixir pg:create --free
```

データベースが作られたことを確かめておきましょう。

```console
$ gigalixir pg
```

`DATABASE_URL` と `POOL_SIZE`が作られたことを確かめておきましょう。

```console
$ gigalixir config
```

## デプロイ!

プロジェクトをGigalixirへデプロイする準備は整いました。
お待ちかねのデプロイをやってみましょう!

```console
$ git push gigalixir master
```

デプロイのステータスをチェックして、アプリが`Healthy`になるまで待ちましょう。

```console
$ gigalixir ps
```

マイグレーションを実行しましょう。

```console
$ gigalixir run mix ecto.migrate
```

アプリのログをチェックしてみましょう。

```console
$ gigalixir logs
```

すべてが正しそうであれば、Gigalixirで稼働しているアプリをみてみましょう。

```console
$ gigalixir open
```

## 便利なGigalixirコマンド

リモートコンソールを開く。

```console
$ gigalixir account:ssh_keys:add "$(cat ~/.ssh/id_rsa.pub)"
$ gigalixir ps:remote_console
```

リモートオブザーバーを開くには、[リモートオブザーバー](https://gigalixir.readthedocs.io/en/latest/runtime.html#how-to-launch-a-remote-observer)を参照してください。

クラスタリングをセットアップしたいなら、[クラスタリングノード](https://gigalixir.readthedocs.io/en/latest/cluster.html)を参照してください。

ホットアップグレードのためには、[ホットアップグレード](https://gigalixir.readthedocs.io/en/latest/deploy.html#how-to-hot-upgrade-an-app)を参照してください。

カスタムドメインをつけたいですとか、スケーリング、ジョブ、その他の機能については、[Gigalixirドキュメント](https://gigalixir.readthedocs.io/)を参照してください。

## トラブルシューティング

[トラブルシューティング](https://gigalixir.readthedocs.io/en/latest/troubleshooting.html)を参照してください。

また、[help@gigalixir.com](mailto:help@gigalixir.com)へEメールを送ることや、[Slack](https://elixir-lang.slack.com)の[招待リンク](https://elixir-slackin.herokuapp.com/)から#gigalixirチャネルに参加することをためらわないでください。
