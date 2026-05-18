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

echo "$(bold 'Sibyl 1-line installer')"
echo

# ---- 1. brew 必須 -----------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "$(red '✗') Homebrew が見つかりません"
  echo "  https://brew.sh の手順で先に Homebrew をインストールしてください"
  echo "  (Apple Silicon Mac は /opt/homebrew、Intel Mac は /usr/local/bin が PATH に通っているか確認)"
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
  if [[ -f "$RC_FILE" ]] && grep -q "^export SIBYL_USER_EMAIL=" "$RC_FILE"; then
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
