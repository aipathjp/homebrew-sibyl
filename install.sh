#!/usr/bin/env bash
# Sibyl 1-line installer for AI-Path 社員
#
# 想定実行:
#   curl -sSL https://raw.githubusercontent.com/aipathjp/homebrew-sibyl/main/install.sh | bash
#
# やること:
#   1. brew が無ければ案内して終了
#   2. brew tap aipathjp/sibyl
#   3. brew install sibyl              ← sib / sibyl-record / sibyl-* skill が /opt/homebrew/share/sibyl に配備
#   4. sibyl-install --skills          ← ~/.claude/skills/<name>/ に symlink
#   5. SIBYL_USER_EMAIL を ~/.zshrc に登録
#   6. 動作確認 (sib --version)
#
# 環境変数:
#   SIBYL_USER_EMAIL: 既に export 済ならそれを使う (idempotent)
#   SIBYL_RC_FILE:    rc ファイル (既定: $HOME/.zshrc)

set -euo pipefail

RC_FILE="${SIBYL_RC_FILE:-$HOME/.zshrc}"

color() { printf '\033[%sm%s\033[0m' "$1" "$2"; }
green() { color '32' "$1"; }
yellow() { color '33' "$1"; }
red()   { color '31' "$1"; }
bold()  { color '1' "$1"; }

# 失敗時に「どこで何のコマンドが失敗したか」を必ず吐く (社員サポート用)
on_err() {
  local exit_code=$?
  local line=$1
  echo
  echo "$(red '✗') install.sh が ${line} 行目で失敗 (exit ${exit_code})"
  echo "  直前に実行されていたコマンド: ${BASH_COMMAND}"
  echo
  echo "  このメッセージを Slack #ai-path にスクショ付きで貼ってください"
  echo "  (どのステップで、どのコマンドが No such file / not found を返したかが分かれば即特定可)"
}
trap 'on_err $LINENO' ERR

echo "$(bold 'Sibyl 1-line installer')"
echo "  OS: $(uname -s) $(uname -m)"
echo "  shell: ${SHELL:-unknown}"
echo "  user: $(id -un)"
echo

# ---- 0. Xcode Command Line Tools (Mac の新マシンで頻発する原因) -------------
# 入っていないと brew tap / brew install の裏で git が xcrun を呼んで
# "xcrun: error: invalid active developer path ... No such file or directory"
# になる。先に検出してユーザーに案内する。
if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "$(red '✗') Xcode Command Line Tools が入っていません"
    echo "  これが無いと brew install の途中で git が"
    echo "    \"xcrun: error: invalid active developer path ... No such file or directory\""
    echo "  になります。先に以下を実行してダイアログで Install を選んでください:"
    echo
    echo "    $(bold 'xcode-select --install')"
    echo
    echo "  完了後にこの install.sh を再実行してください。"
    exit 1
  fi
  echo "$(green '✓') Xcode CLT: $(xcode-select -p)"
fi

# ---- 1. brew 必須 -----------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  # PATH に通っていないだけのケース (新 Apple Silicon Mac で shellenv 未設定)
  for cand in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$cand" ]]; then
      echo "$(yellow '⚠') brew は $cand に存在しますが PATH に通っていません"
      echo "  以下を ~/.zshrc に追記し、新シェルを開いてから再実行してください:"
      echo
      echo "    $(bold "eval \"\$($cand shellenv)\"")"
      echo
      echo "  今回だけ続行するため、当該 shellenv を一時 eval します..."
      eval "$($cand shellenv)"
      break
    fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "$(red '✗') Homebrew が見つかりません"
  echo "  https://brew.sh の手順で先に Homebrew をインストールしてください:"
  echo
  echo "    $(bold '/bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')"
  echo
  exit 1
fi
echo "$(green '✓') Homebrew: $(brew --prefix)"

# ---- 2. tap ------------------------------------------------------------------
if brew tap | grep -q '^aipathjp/sibyl$'; then
  echo "$(green '✓') tap aipathjp/sibyl 済"
else
  echo "▶ brew tap aipathjp/sibyl"
  brew tap aipathjp/sibyl
fi

# ---- 3. install (or reinstall to latest) -------------------------------------
if brew list sibyl >/dev/null 2>&1; then
  echo "▶ brew upgrade sibyl"
  brew upgrade sibyl || true
else
  echo "▶ brew install sibyl"
  brew install sibyl
fi

# ---- 4. skills を ~/.claude/skills/ に symlink -------------------------------
SHARE="$(brew --prefix)/share/sibyl"
if [[ ! -d "$SHARE" ]]; then
  echo "$(red '✗') $SHARE が見つかりません (brew install sibyl が壊れている可能性)"
  echo "  brew reinstall sibyl を試してください"
  exit 1
fi
echo "▶ SIBYL_BREW_SHARE=$SHARE sibyl-install --skills"
SIBYL_BREW_SHARE="$SHARE" sibyl-install --skills

# ---- 5. SIBYL_USER_EMAIL ----------------------------------------------------
EMAIL="${SIBYL_USER_EMAIL:-}"
if [[ -z "$EMAIL" ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  EMAIL="$(gh api user --jq '.email // empty' 2>/dev/null || true)"
fi
if [[ -z "$EMAIL" ]]; then
  EMAIL="$(git config --global user.email 2>/dev/null || true)"
fi
if [[ -z "$EMAIL" ]]; then
  echo
  echo "$(bold 'SIBYL_USER_EMAIL') を入力してください (例: yourname@ai-path.jp):"
  if [[ -t 0 ]]; then
    read -r EMAIL
  elif [[ -r /dev/tty ]]; then
    read -r EMAIL < /dev/tty
  fi
fi

if [[ -z "$EMAIL" || "$EMAIL" != *"@"* ]]; then
  echo "$(yellow '⚠') email 未設定。後で手動で ~/.zshrc に追記してください:"
  echo "    export SIBYL_USER_EMAIL=\"yourname@ai-path.jp\""
else
  if [[ "$EMAIL" != *"@ai-path.jp" ]]; then
    echo "$(yellow '⚠') $EMAIL は @ai-path.jp ドメインではありません。Sibyl は @ai-path.jp 限定です"
  fi
  # 新マシンで RC_FILE が無いケースをハンドル (touch で作る)
  if [[ ! -f "$RC_FILE" ]]; then
    mkdir -p "$(dirname "$RC_FILE")"
    : > "$RC_FILE"
    echo "$(green '✓') $RC_FILE を新規作成"
  fi
  if grep -q "^export SIBYL_USER_EMAIL=" "$RC_FILE" 2>/dev/null; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      sed -i '' "s|^export SIBYL_USER_EMAIL=.*|export SIBYL_USER_EMAIL=\"$EMAIL\"|" "$RC_FILE"
    else
      sed -i "s|^export SIBYL_USER_EMAIL=.*|export SIBYL_USER_EMAIL=\"$EMAIL\"|" "$RC_FILE"
    fi
    echo "$(green '✓') $RC_FILE の SIBYL_USER_EMAIL を $EMAIL に更新"
  else
    printf '\n# Sibyl\nexport SIBYL_USER_EMAIL="%s"\n' "$EMAIL" >> "$RC_FILE"
    echo "$(green '✓') $RC_FILE に SIBYL_USER_EMAIL=$EMAIL を追記"
  fi
fi

# ---- 6. 動作確認 ------------------------------------------------------------
echo
echo "$(bold '動作確認:')"
if command -v sib >/dev/null 2>&1; then
  echo "$(green '✓') sib: $(command -v sib)"
  sib --version 2>/dev/null || true
else
  echo "$(yellow '⚠') sib が PATH に無い。新シェルを開くか source $RC_FILE してください"
fi

echo
echo "$(bold 'セットアップ完了')"
echo
echo "  次にやること:"
echo "    1) $(bold 'sib login')    # Google Workspace SSO で認証 (@ai-path.jp 限定)"
echo "    2) $(bold 'sib status')   # 認証状態と workstation 情報を確認"
echo
echo "  自然言語起動 (Claude Code / Codex):"
echo "    「Sibyl に記録」「checkout」「セッションを残す」等で自動発火"
echo
echo "  Web: https://sibyl.ai-path.jp"
