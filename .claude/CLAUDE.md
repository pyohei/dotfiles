# GitHub の操作

Issue / Pull Request / それらへのコメントは、Claude 用の GitHub App 名義で出す。
人間のレビューを挟めるようにするため、作成者を人間と分ける。

```sh
GH_TOKEN=$(pyohei-ai token claude) gh issue create ...
GH_TOKEN=$(pyohei-ai token claude) gh pr create ...
```

- コミットと push には `GH_TOKEN` を付けない。著者はユーザー名義のまま残す。
- `pyohei-ai token` を単体で実行しない。トークンが会話ログに残る。
  必ず上の形で、コマンドに直接渡す。
- App が入っていないリポジトリでは 404 になる。黙って個人名義へ切り替えず、
  App のインストールが必要だと伝える。
