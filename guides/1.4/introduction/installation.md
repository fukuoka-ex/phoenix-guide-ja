---
layout: default
group: introduction
title: インストール
nav_order: 2
hash: 3161ec8b32414565d97ac864b67311d405e58a98
---

# インストール

[概要](overview.html)で、Phoenixエコシステムと各要素の相互関係を確認しました。 [起動ガイド](../up_and_running.html)へ進む前に、必要なソフトウェアをインストールします。

このリストを見て、システムに必要なものをすべてインストールしてください。事前に依存関係をインストールしておくと、あとでイライラする問題を防ぐことができます。

### Elixir 1.5以降

PhoenixはElixirで書かれており、アプリケーションコードもElixirで書かれます。ElixirなしではPhoenixもうまくいかないでしょう！ Elixirサイトには、役立つ[インストールページ](https://elixir-lang.org/install.html)が用意されています。

Elixirをはじめてインストールしたばかりの場合は、Hexパッケージマネージャーもインストールする必要があります。 Hexは、Phoenixアプリを（依存関係をインストールして）実行し、途中で必要になる可能性のある追加の依存関係をインストールするために必要です。

Hexをインストールするコマンドは次のとおりです（Hexがすでにインストールされている場合、Hexは最新バージョンにアップグレードされます）。

```console
$ mix local.hex
```

### Erlang 18以降

ElixirコードはErlangバイトコードにコンパイルされ、Erlang仮想マシンで実行されます。 Erlangがない場合、Elixirコードには実行する仮想マシンがないため、Erlangもインストールする必要があります。

Elixirの[インストールページ](https://elixir-lang.org/install.html)にしたがってElixirをインストールすると、通常はErlangも取得されます。 Elixirと共にErlangがインストールされていない場合は、Elixirインストールページの[Erlang Instructions](https://elixir-lang.org/install.html#installing-erlang)セクションで手順を参照してください。

Debianベースのシステムを使用している人は、必要なすべてのパッケージを入手するために、明示的にErlangをインストールする必要があります。

```console
$ wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
$ sudo apt-get update
$ sudo apt-get install esl-erlang
```

### Phoenix

Elixir 1.5およびErlang 18以降を使用していることを確認するには、次を実行します。

```console
elixir -v
Erlang/OTP 19 [erts-8.3] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Elixir 1.5.3
```

ElixirとErlangができたら、Phoenix Mixアーカイブをインストールする準備ができました。 Mixアーカイブは、アプリケーションとそのコンパイル済みBEAMファイルを含むZipファイルです。アプリケーションの特定のバージョンに関連付けられています。アーカイブは、ビルド可能な新しいベースPhoenixアプリケーションを生成するために使用するものです。

Phoenixアーカイブをインストールするコマンドは次のとおりです。

```console
$ mix archive.install hex phx_new 1.4.16
```

### Plug、Cowboy、およびEcto

これらは、デフォルトでPhoenixアプリケーションの一部であるElixirまたはErlangプロジェクトです。それらをインストールするために特別なことをする必要はありません。新しいアプリケーションを作成するときにMixに依存関係をインストールさせると、これらは自動的にインストールされます。そうでない場合、Phoenixはアプリの作成が完了した後、その方法を教えてくれます。

### node.js（>= 5.0.0）

Nodeは任意の依存関係です。 Phoenixはデフォルトで[webpack](https://webpack.js.org/)を使用して静的アセット（JavaScript、CSSなど）をコンパイルします。 webpackは、ノードパッケージマネージャー（npm）を使用して依存関係をインストールします。npmにはnode.jsが必要です。

静的アセットがない場合、または別のビルドツールを使用する場合、新しいアプリケーションを作成するときに `--no-webpack`フラグを渡すことができ、ノードは不要です。

node.jsは[ダウンロードページ](https://nodejs.org/en/download/)から取得できます。ダウンロードするパッケージを選択する場合、Phoenixにはバージョン5.0.0以降が必要であることに注意してください。

Mac OS Xユーザーは、[homebrew](https://brew.sh/)を介してnode.jsをインストールすることもできます。

注：Node.jsを元にしたnpm互換プラットフォームであるio.jsは、Phoenixで動作するかは不明です。

Debian/Ubuntuユーザーには、次のようなエラーが表示される場合があります。
```console
sh: 1: node: not found
npm WARN This failure might be due to the use of legacy binary "node"
```
これは、Debianがノードの競合するバイナリを持っているためです：[stackoverflowについての議論](http://stackoverflow.com/questions/21168141/can-not-install-packages-using-node-package-manager-in-ubuntu)

この問題を解決するには、次の2つのオプションがあります。
- nodejs-legacyをインストールする
```console
$ apt-get install nodejs-legacy
```
または
- シンボリックリンクを作成する
```console
$ ln -s /usr/bin/nodejs /usr/bin/node
```

### PostgreSQL

PostgreSQLはリレーショナルデータベースサーバーです。 Phoenixはデフォルトでそれを使用するようにアプリケーションを設定しますが、新しいアプリケーションを作成するときに `--database mysql`フラグを渡すことでMySQLに切り替えることができます。

これらのガイドでEctoスキーマを使用する場合、PostgreSQLおよびPostgrexアダプターを使用します。例に沿って進むには、PostgreSQLをインストールしてサーバーを起動する必要があります。 PostgreSQL wikiには、さまざまなシステム用の[インストールガイド](https://wiki.postgresql.org/wiki/Detailed_installation_guides)があります。

Postgrexは、Phoenixの直接的な依存関係であり、アプリのビルドを開始すると、残りの依存関係とともに自動的にインストールされます。

### inotify-tools（Linuxユーザー向け）

これは、Phoenixがライブコードリロードに使用するLinux専用のファイルシステムウォッチャーです。（Mac OS XまたはWindowsユーザーは安全に無視できます。）

Linuxユーザーは、この依存関係をインストールする必要があります。ディストリビューション固有のインストール手順については、[inotify-tools wiki](https://github.com/rvoicilas/inotify-tools/wiki)を参照してください。

### 最初のPhoenixアプリケーション

すべてのインストールが完了したので、最初のPhoenixアプリケーションを作成して[起動ガイド](../up_and_running.html)に進みましょう。
