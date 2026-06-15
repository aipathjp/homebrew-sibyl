# Sibyl を Windows で使う (WSL セットアップ)

Sibyl の CLI (`sib`) と `sibyl-*` skill は Homebrew で配布しているため、配布対象は macOS / Linux です。
**Windows では WSL2 (Ubuntu) の中に Linux 版をインストールして使います。** 本ドキュメントはその手順書です。

> 前提: WSL2 (Ubuntu 推奨) が既にインストール済みであること。
> 未導入の場合は PowerShell (管理者) で `wsl --install` を実行し、再起動後に Ubuntu を初期セットアップしてください。

---

## なぜ WSL なのか

`sib` 本体 (Bun+TypeScript) はクロスプラットフォームで、認証情報の保存層も
`@napi-rs/keyring` (macOS Keychain / Windows Credential Manager / GNOME Keyring) を抽象化しています。
一方で配布は Homebrew、インストーラと `sibyl-*` ラッパーは bash 製のため、Windows では
**WSL = Linux 環境としてそのまま動かす**のが最も確実で、挙動も macOS/Linux と完全に同一になります。

---

## WSL 特有の 3 つの差分 (必ず対応)

| 差分 | 理由 | 対処 |
|---|---|---|
| **① `sib login` がトークン保存で失敗する** | Linux 版は Secret Service (GNOME Keyring) が必須だが、WSL は既定で起動していない。トークン保存処理は失敗時にフォールバックせず例外を投げる | `gnome-keyring` を入れ、`~/.bashrc` で自動起動する (手順 1〜2) |
| **② `SIBYL_USER_EMAIL` が反映されない** | インストーラの既定 rc は `~/.zshrc` だが、WSL Ubuntu の既定シェルは **bash** (`~/.bashrc`) | `SIBYL_RC_FILE=$HOME/.bashrc` を付けて実行 (手順 3) |
| **③ skill をエージェントが拾えない** | skill は WSL 側の `~/.claude/skills` にコピーされる | **Claude Code / Codex も WSL の中から起動**する (手順 5) |

> Homebrew のサードパーティ tap-trust ゲート (`brew trust`) は linuxbrew でも効きますが、
> 配布ワンライナー (`install.sh`) が自動で `brew trust` を実行するため追加対応は不要です。
> 設定ファイル `~/.aipsibyl/config.toml` は通常ファイルなので問題ありません。

---

## 手順 (WSL Ubuntu のターミナルで実行)

### 1. 前提パッケージ + GNOME Keyring を入れる (① の対処)

```bash
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git \
  gnome-keyring libsecret-1-0 dbus-x11
```

### 2. `~/.bashrc` に Secret Service 自動起動を追記 (① の対処)

```bash
cat >> ~/.bashrc <<'EOF'

# --- WSL: sib login のトークン保存用に Secret Service を起動 ---
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  eval "$(dbus-launch --sh-syntax)"
fi
if ! pgrep -u "$USER" gnome-keyring-daemon >/dev/null 2>&1; then
  eval "$(printf '\n' | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)"
  export GNOME_KEYRING_CONTROL
fi
EOF
exec bash -l   # 反映
```

> 初回はパスワード空のログインキーリングが作られます。社内端末前提でこの運用で問題ありません。

### 3. ワンライナーでインストール (② の対処込み)

```bash
SIBYL_RC_FILE="$HOME/.bashrc" \
  bash -c 'curl -sSL https://raw.githubusercontent.com/aipathjp/homebrew-sibyl/main/install.sh | bash'
exec bash -l
```

これで linuxbrew 経由で `sib` バイナリ + `sibyl-*` skill 一式が入り、tap-trust も自動で処理されます。

### 4. ログイン確認

```bash
sib login     # 手順 2 のキーリングが効いていればトークンが保存される
sib status    # 認証 OK と workstation 情報が出れば成功
```

`sib login` は Device Authorization Grant です。表示された code (例 `ABCD-1234`) を
ブラウザの https://sibyl.ai-path.jp/cli/auth に入力 → Google (@ai-path.jp) で認証してください。

### 5. エージェントも WSL の中から起動する (③ の対処・最重要)

```bash
cd <作業プロジェクト>      # WSL 内のパスで (/mnt/c/... の Windows 領域でも可)
claude                    # ← WSL のシェルから起動。これで sibyl-* skill が発火する
# Codex を使う場合も WSL から: codex
```

> **Windows ネイティブの Claude Code から使うと、skill は `C:\Users\...\.claude\skills` を参照するため
> WSL 側のコピーが見えません。** 「Sibyl に記録」「checkout」などを使う作業は、必ず
> WSL のターミナルから `claude` / `codex` を起動してください。

---

## 動作確認チェックリスト

- [ ] `sib --version` がバージョンを返す
- [ ] `sib status` で認証済み・workstation 情報が出る
- [ ] `echo $SIBYL_USER_EMAIL` が自分の `@ai-path.jp` を返す
- [ ] WSL のシェルから `claude` を起動し、「Sibyl に記録」等が発火する

---

## トラブルシュート

### `sib login` 後に `Keychain に refresh token がありません` / 保存時にエラー

手順 1〜2 の GNOME Keyring が動いていません。新しいシェルを開き直し (`exec bash -l`)、
`pgrep -u "$USER" gnome-keyring-daemon` でデーモンが動いているか確認してください。

### `sibyl-bootstrap` 等が「Sibyl に記録」で発火しない

エージェントを Windows ネイティブ側で起動している可能性があります (手順 5)。
`ls ~/.claude/skills` に `sibyl-*` が並んでいるか WSL 内で確認し、`claude` を WSL から起動し直してください。

### `Refusing to load formula ... from untrusted tap`

linuxbrew でも tap-trust が必要です。`brew trust aipathjp/sibyl` を実行してから再度インストールしてください
(最新のワンライナーは自動実行します)。

---

## 補足: より楽にする恒久対応 (任意)

手順 1〜2 の GNOME Keyring 起動を社員ごとに行うのが負担な場合、`sib` 側に
「Secret Service 不可時の暗号化ファイルフォールバック (`~/.aipsibyl/` に 0600 保存)」を実装すれば、
WSL でも追加セットアップ無しで `sib login` が通るようになります。WSL を全社展開する場合はこの恒久対応を推奨します。
