---
layout: 1.5/layout
version: 1.5
group: introduction
title: インストール
nav_order: 2
hash: a9623ba8
---

# インストール

Phoenixアプリケーションを構築するためには、オペレーティング・システムにインストールされているいくつかの依存関係が必要です。

  * Erlang VMとElixirプログラミング言語
  * データベース - PhoenixはPostgreSQLを推奨していますが、他のものを選ぶこともできますし、データベースをまったく使わないこともできます。
  * アセットのためのNode.JS - とくにAPIを構築している場合は、オプトアウトできます。
  * その他、オプションパッケージ

このリストを見て、システムに必要なものをインストールしてください。依存関係を事前にインストールしておくことで、後々のイライラした問題を防ぐことができます。

## Elixir 1.6以降

PhoenixはElixirで書かれており、私たちのアプリケーションコードもElixirで書かれます。ElixirなしではPhoenixアプリを作ることはできません！Elixirのサイトでは、素晴らしい[インストールページ](https://elixir-lang.org/install.html)が用意されています。

初めてElixirをインストールしたばかりの場合は、Hexパッケージマネージャもインストールする必要があります。Hexは、（依存関係をインストールすることで）Phoenixアプリを動かすために必要であり、途中で必要になるかもしれない追加の依存関係をインストールするためにも必要です。

以下は、Hexをインストールするコマンドです（Hexが既にインストールされている場合は、Hexを最新バージョンにアップグレードします）。

```console
$ mix local.hex
```

## Erlang 20以降

ElixirのコードはErlangのバイトコードにコンパイルしてErlang仮想マシン上で実行します。Erlangがなければ、Elixirのコードは仮想マシン上で実行することができないので、Erlangもインストールする必要があります。

Elixirの[インストールページ](https://elixir-lang.org/install.html)の指示にしたがってElixirをインストールすると、通常はErlangもインストールされます。もしErlangがElixirと一緒にインストールされていない場合は、インストールページの[Erlangのインストール](https://elixir-lang.org/install.html#installing-erlang)のセクションを見てください。

## Phoenix

Elixir 1.6とErlang 20以降であることを確認するには、次のように実行してください。

```console
elixir -v
Erlang/OTP 20 [erts-9.3] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Elixir 1.6.3
```

ElixirとErlangを手に入れたら、Phoenixアプリケーションジェネレーターをインストールする準備ができました。

```console
$ mix archive.install hex phx_new 1.5.1
```

[起動ガイド](up_and_running.html)という次回のガイドでは、このジェネレーターを使って新しいアプリケーションを生成していきます。

## node.js

Nodeは任意の依存関係です。Phoenixは、静的アセット（JavaScript、CSSなど）のコンパイルに[webpack](https://webpack.js.org/)をデフォルトで使用します。webpackはnodeパッケージマネージャ(npm)を使用して依存関係をインストールし、npmはnode.jsを必要とします。

静的アセットがない場合や別のビルドツールを使いたい場合は、新しいアプリケーションを作成する際に `--no-webpack` フラグを指定すれば、nodeはまったく必要ありません。

node.jsは[ダウンロードページ](https://nodejs.org/en/download/)から取得できます。ダウンロードするパッケージを選択する際に、Phoenixのバージョンが5.0.0以上を要求することに注意してください。

Mac OS Xの方は、[homebrew](https://brew.sh/)からnode.jsをインストールすることもできます。

## PostgreSQL

PostgreSQLはリレーショナルデータベースサーバーです。PhoenixはデフォルトでPostgreSQLを使用するようにアプリケーションを設定しますが、新しいアプリケーションを作成する際に `--database` フラグを渡すことで、MySQLやMSSQLに切り替えることができます。

データベースと通信するために、Phoenixアプリケーションは[Ecto](https://github.com/elixir-ecto/ecto)と呼ばれる別のElixirパッケージを使用します。アプリケーションでデータベースを使用する予定がない場合は、`--no-ecto` フラグを渡すことができます。

しかし、Phoenixを使い始めたばかりの場合は、PostgreSQLをインストールして動作確認することをお勧めします。PostgreSQL wikiには、さまざまなシステムのための[インストールガイド](https://wiki.postgresql.org/wiki/Detailed_installation_guides)があります。

## inotify-tools (linuxユーザー用)

Phoenixには、ライブリロードと呼ばれる非常に便利な機能があります。ビューやアセットを変更すると、ブラウザ上で自動的にページをリロードします。この機能を利用するには、ファイルシステムウォッチャーが必要です。

Mac OS XとWindowsユーザーはすでにファイルシステムウォッチャーを持っていますが、Linuxユーザーはinotify-toolsをインストールする必要があります。ディストリビューションごとのインストール方法については [inotify-tools wiki](https://github.com/rvoicilas/inotify-tools/wiki) を参照してください。

## まとめ

このセクションの最後に、Elixir、Hex、Phoenix、PostgreSQL、node.jsをインストールしておく必要があります。これですべてのインストールが完了したので、最初のPhoenixアプリケーションを作成して、[起動](up_and_running.html)させましょう。
