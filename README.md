# homebrew-sibyl

Sibyl の **Homebrew tap** (public)。AI-Path 株式会社の社内 CLI / skill を全社員のマシンに 1 行で配備するためのフォーミュラを置いています。

> aipsibyl 本体リポは private (collaborator 限定) ですが、CLI 配布物 (バイナリ + skill) は本 tap と [aipathjp/sibyl-dist](https://github.com/aipathjp/sibyl-dist) (どちらも public) から入手できます。

---

## ワンライナーで全部入れる (推奨)

```
curl -sSL https://raw.githubusercontent.com/aipathjp/homebrew-sibyl/main/install.sh | bash
```

これが裏でやること:

1. `brew tap aipathjp/sibyl`
2. `brew install sibyl` (`sib` バイナリ + `sibyl-record` / `sibyl-log-session` / `sibyl-install` + `sibyl-*` skill 一式を `$(brew --prefix)/share/sibyl` に配備)
3. `SIBYL_BREW_SHARE=... sibyl-install --skills` (全 `sibyl-*` skill を `~/.claude/skills/<name>/` に symlink。Claude Code から `/sibyl-bootstrap` 等が即時呼べる)
4. `SIBYL_USER_EMAIL` を `~/.zshrc` に登録 (`gh` / `git config` で自動検出、無ければ tty から入力)
5. `sib --version` で動作確認

## 手動でやる場合

```
brew tap aipathjp/sibyl
brew install sibyl
SIBYL_BREW_SHARE="$(brew --prefix)/share/sibyl" sibyl-install --skills
echo 'export SIBYL_USER_EMAIL="yourname@ai-path.jp"' >> ~/.zshrc
exec $SHELL -l
```

## 初回ログイン

```
sib login        # Google Workspace SSO (@ai-path.jp 限定) で認証
sib status       # 認証情報と workstation 情報を確認
```

`sib login` は Device Authorization Grant です。表示された code (例 `ABCD-1234`) をブラウザの https://sibyl.ai-path.jp/cli/auth に入力 → Google で認証 → CLI が API key を OS Keychain (Service: `aipsibyl` / Account: `<email>`) に保存します。

## 更新

```
brew update
brew upgrade sibyl
```

## トラブルシュート

### `sib: command not found`

```
brew --prefix             # /opt/homebrew (Apple Silicon) or /usr/local (Intel)
ls $(brew --prefix)/bin/sib
echo $PATH | tr ':' '\n' | grep -E 'homebrew|/usr/local'
```

PATH に `$(brew --prefix)/bin` が入っていない場合は `~/.zshrc` に追記して新シェルを開いてください。

### SHA256 mismatch

過去に古い tap をキャッシュしていると起きます:

```
brew untap aipathjp/sibyl
brew update
brew tap aipathjp/sibyl
brew install sibyl
```

### `sibyl-install --skills` が失敗

Homebrew 5.x の post_install サンドボックスが `$HOME/.claude/skills` への mkdir を block するため、`brew install` の post_install では実行せず別コマンドに分離しています。必ず `SIBYL_BREW_SHARE` を明示して実行してください:

```
SIBYL_BREW_SHARE="$(brew --prefix)/share/sibyl" sibyl-install --skills
```

## リリース運用 (admin)

このリポは **配布構造のみ** を持ちます。

- [`Formula/sibyl.rb`](Formula/sibyl.rb) — 単一フォーミュラ。url + sha256 をプラットフォーム別に持つ
- [`install.sh`](install.sh) — curl one-liner 用ブートストラップ

実際のバイナリ (`sib` + `sibyl-record` + `sibyl-log-session` + `sibyl-install` + `skills/`) を tarball にして配るリポは [aipathjp/sibyl-dist](https://github.com/aipathjp/sibyl-dist)。`sib release` コマンドが:

1. `bun build --compile --target=...` で各プラットフォーム向けバイナリをビルド
2. tarball + SHA256SUMS を `sibyl-dist` の Release に publish
3. 本リポの `Formula/sibyl.rb` に PR を起票 (url + sha256 + version を更新)

詳細: https://github.com/aipathjp/aipsibyl/blob/main/docs/RUNBOOK.md (collaborator のみ可視)
