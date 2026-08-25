# pyohei-ai

GitHub App の installation token を発行する CLI。複数の App を使い分けられる。

個人アカウントの認証（`gh auth login` など）とは別系統で、App に与えた権限の
範囲に限定されたトークンを、必要なときに都度発行して使う。

## インストール

リポジトリ直下の `install.sh` が `.local/bin` を `~/.local/bin` へコピーする。
AI 向けの規約ファイル（`.claude/CLAUDE.md`、`.codex/AGENTS.md`）も同時に配られる。

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

### 何を App 名義にするか

App 名義にするのは **Issue / Pull Request / それらへのコメント** だけ。コミットと
push は個人名義のまま残す。

こうすると、コードの著者は自分のまま、AI が出した変更は AI 名義の Pull Request
として届く。GitHub は自分が作成した Pull Request を自分で approve できないので、
作成者を分けておくと個人開発でもレビューが成立する。AI ごとに App を分ければ、
AI 同士のやり取りも GitHub 上に別々の主体として記録される。

コミットの著者は `user.name` / `user.email` で決まる。push に使うトークンとは
無関係なので、push が App 経由かどうかは著者名に影響しない。

### gh コマンド

`GH_TOKEN` は `gh auth login` で保存した認証より優先される。そのコマンドの間だけ
App として振る舞う。

```sh
GH_TOKEN=$(pyohei-ai token claude) gh issue create --title ... --body ...
GH_TOKEN=$(pyohei-ai token claude) gh pr create --fill
GH_TOKEN=$(pyohei-ai token codex)  gh pr comment 12 --body ...
```

**トークンを画面に出さない。** `pyohei-ai token claude` を単体で実行すると標準出力に
そのまま出るので、エージェントに実行させると会話ログや履歴ファイルに 1 時間有効な
認証情報が残る。上のようにコマンド置換で直接渡す。

**保存しない。** 有効期限は発行から 1 時間。ファイルや環境変数に貯めず、使う直前に
発行する。期限切れは 401 で失敗するだけで、黙って壊れることはない。

### git

何も設定しない。push は個人の認証情報のまま通り、コミットは自分名義で残る。

git の credential helper で App のトークンを使わせることもできるが、上記の
方針では push を App 名義にする理由がない。`gh` にも効かないので、この用途では
設定しない。

### MCP サーバ

GitHub の MCP サーバに静的な環境変数としてトークンを渡す構成は、1 時間で失効する
ため相性が悪い。使うなら、サーバの起動コマンドをラッパースクリプトにして、起動の
たびに `pyohei-ai token` で発行させる。

### 依頼の仕方

毎回頼まなくて済むよう、規約として置いておく。このリポジトリでは
`.claude/CLAUDE.md` と `.codex/AGENTS.md` に書き、`install.sh` が
`~/.claude/` と `~/.codex/` へ配る。

エージェントには「トークン」ではなく「トークンの取り方」を渡す。トークンそのものを
会話に貼り付けると、ログに残るうえ 1 時間で使えなくなる。

### 前提

App が対象リポジトリにインストールされていること。インストールされていなければ
API は 404 を返す。AI ごとに App を分ける場合、両方の AI に触らせたい
リポジトリには両方の App を入れておく。

必要な権限は Issues: Read & write、Pull requests: Read & write、Contents: Read。
App 名義で push もさせるなら Contents も Write にする。

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
