# pyohei-ai

GitHub App の installation token を発行する CLI。複数の App を使い分けられる。

個人アカウントの認証（`gh auth login` など）とは別系統で、App に与えた権限の
範囲に限定されたトークンを、必要なときに都度発行して使う。

## インストール

リポジトリ直下の `install.sh` が `.local/bin` を `~/.local/bin` へコピーする。

```sh
./install.sh -n   # 何がコピーされるか確認
./install.sh      # 実行
```

`~/.local/bin` に PATH が通っていれば `pyohei-ai` として呼べる。

## 設定

App ごとに 1 ディレクトリ。設定と鍵が同じ場所に収まる。

```
~/.config/pyohei-ai/
└── apps/
    ├── codex/
    │   ├── app.env
    │   └── private-key.pem
    └── claude/
        ├── app.env
        └── private-key.pem
```

`app.env` に書くのは 2 つだけ。

```
GITHUB_APP_ID=<App ID>
GITHUB_APP_INSTALLATION_ID=<Installation ID>
```

鍵はデフォルトで同ディレクトリの `private-key.pem` を読む。別名のまま置きたい
ときは `GITHUB_APP_PRIVATE_KEY_PATH` を足す。相対パスは App ディレクトリ基準で
解決されるので、ファイル名だけ書けばよい。

```
GITHUB_APP_PRIVATE_KEY_PATH=my-app.2026-08-25.private-key.pem
```

複数の App が同じ鍵を共有する場合（1 つの App を複数箇所にインストールした場合）
は、絶対パスを書いて鍵を 1 つにまとめる。

鍵と設定はディレクトリごと権限を絞っておく。

```sh
chmod 700 ~/.config/pyohei-ai/apps/codex
chmod 600 ~/.config/pyohei-ai/apps/codex/*
```

### App ID と Installation ID

App ID は App の設定画面に表示される。Installation ID は App をインストールした
先ごとに決まり、Configure 画面の URL 末尾に出る。

```
https://github.com/settings/installations/149020819
                                          ^^^^^^^^^
```

Organization にインストールした場合は
`https://github.com/organizations/<org>/settings/installations/<id>`。

### 設定の探索順

1. `$GITHUB_APP_CONFIG_PATH`（ファイルを直接指定。App 名より優先）
2. `apps/<name>/app.env`
3. `apps/<name>.env`（旧レイアウト）

暗黙の既定 App は無い。設定ディレクトリ直下の `app.env` は読まれないので、
残っていても消してよい。

## コマンド

```sh
pyohei-ai list           # 設定済みの App を一覧
pyohei-ai token codex    # App を指定してトークンを発行
pyohei-ai help
```

App は必ず名指しする。省略すると `PYOHEI_AI_APP` を見て、それも無ければ
エラーになる。どの App を使ったか分からないまま動くことはない。

```sh
export PYOHEI_AI_APP=codex   # 名前を省いたときに使う App
```

## AI エージェントに使わせる

### 原則

**トークンを画面に出さない。** `pyohei-ai token codex` は標準出力にトークンを
そのまま出すので、エージェントに単体で実行させると会話ログや履歴ファイルに
生のトークンが残る。値を経由させず、コマンド置換でそのまま渡す。

```sh
GH_TOKEN=$(pyohei-ai token codex) gh pr list
```

**保存しない。** installation token の有効期限は発行から 1 時間。ファイルや
シェルの環境変数に貯めず、使う直前に発行する。期限切れは 401 で失敗するだけで、
黙って壊れることはない。

### gh コマンド

`GH_TOKEN` は `gh auth login` で保存した認証より優先される。その 1 コマンドの
間だけ App として振る舞う。

```sh
GH_TOKEN=$(pyohei-ai token codex) gh issue list --repo owner/repo
```

### git の push / clone

一時的な credential helper を使うと、トークンが `.git/config` にも
`~/.git-credentials` にも残らない。

```sh
git -c credential.helper='!f() { echo username=x-access-token; echo password=$(pyohei-ai token codex); }; f' push
```

リモート URL に `https://x-access-token:<token>@github.com/...` と直接埋める方法は
`.git/config` にトークンが平文で残るので使わない。

### MCP サーバ

GitHub の MCP サーバに静的な環境変数としてトークンを渡す構成は、1 時間で失効する
ため相性が悪い。使うなら、サーバの起動コマンドをラッパースクリプトにして、
起動のたびに `pyohei-ai token` で発行させる。長時間動かすなら失効を前提に、
再起動で拾い直せる形にしておく。

### 依頼の仕方

エージェントには「トークン」ではなく「トークンの取り方」を渡す。プロンプトや
`CLAUDE.md` / `AGENTS.md` にこう書いておけばよい。

> GitHub を操作するときは個人の `gh` 認証ではなく GitHub App を使うこと。
> `GH_TOKEN=$(pyohei-ai token codex) gh ...` の形で実行する。
> `pyohei-ai token` を単体で実行してトークンを表示してはいけない。

トークンそのものを会話に貼り付けて渡すのは避ける。ログに残るうえ、1 時間で
使えなくなる。

## うまくいかないとき

| 症状 | 原因 |
| --- | --- |
| `command not found: pyohei-ai` | `./install.sh` を実行していない |
| `Unknown app "x"` | `apps/x/app.env` が無い。`pyohei-ai list` で確認 |
| `No app given` | App 名を渡すか `PYOHEI_AI_APP` を設定する |
| `ENOENT ... private-key.pem` | 鍵が置かれていない。エラーに探したパスが出る |
| `401` | App ID と鍵の App が食い違っている。JWT の署名検証に失敗している |
| `404` | Installation ID が違うか、App がその対象にインストールされていない |
| トークンは出るが権限不足 | App の権限設定か、インストール時のリポジトリ選択を見直す |
