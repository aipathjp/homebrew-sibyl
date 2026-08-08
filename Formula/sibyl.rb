# Homebrew tap formula — aipathjp/homebrew-sibyl
#
# Phase 7 改訂: bun-compile した sib バイナリ (~63MB) も配布対象に追加。
#
# 配布対象:
#   - bin/sib                          (bun-compile Mach-O / ELF、各 arch ビルド)
#   - bin/sibyl-record / sibyl-log-session / sibyl-install
#   - bin/sibyl-bootstrap / sibyl-intake / sibyl-checkout (multi-agent wrapper)
#   - skills/sibyl-record/{SKILL.md, codex-memory.md}
#   - codex-plugin/sibyl/{.codex-plugin/plugin.json,commands/*.md}
#   - AGENTS.md
#
# 注意: 旧 v0.3.x までは `.claude/commands/sibyl-record.md` (slash command) も配布していたが、
# 最近の Claude Code では skill が自動的に /<name> として登録されるため、同名 slash command を
# 並存させると Skill ツールで "Unknown skill" エラー (重複名による曖昧解決失敗) が発生する。
# v0.4.1 以降、slash command 配布を廃止し skill 一本化。
#
# 配布元: aipathjp/sibyl-dist の GitHub Releases
#   url: https://github.com/aipathjp/sibyl-dist/releases/download/v<VERSION>/sibyl-<VERSION>-<platform>-<arch>.tar.gz
#
# 運用 (sib release コマンドが自動化):
#   1. cli/ で `bun build --compile --target=bun-darwin-arm64 --outfile dist/sib`
#   2. tarball に bin / skills / codex-plugin を集約
#   3. shasum -a 256 で sha256 計算
#   4. gh release create v<VERSION> --repo aipathjp/sibyl-dist tarball
#   5. この Formula の url / sha256 / version を gh pr で aipathjp/homebrew-sibyl に更新

class Sibyl < Formula
  desc "Sibyl: AI-Path 株式会社の AI セッション記録 + transcript 統合 CLI"
  homepage "https://github.com/aipathjp/aipsibyl"
  license "Proprietary"
  version "0.7.16"

  on_macos do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.7.16/sibyl-0.7.16-darwin-arm64.tar.gz"
      sha256 "54d4a065da679e5c41d1095c705b7fe0cad0e1417c8b65bda8fb854e20b9fa34"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.7.16/sibyl-0.7.16-darwin-x64.tar.gz"
      sha256 "e262f2c78fa3ff3396168a71130762497ed1af2d4eb2ba7fa97e62e56c6eb5bd"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.7.16/sibyl-0.7.16-linux-arm64.tar.gz"
      sha256 "328b386f590152e4627a59ba8df292a4a536fe75f23b2763d6d4badc52a955c8"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.7.16/sibyl-0.7.16-linux-x64.tar.gz"
      sha256 "205f84b8d8e8d60e9bfda14f2450caead6fe57dc29d88b8873adea7f1f86de12"
    end
  end

  def install
    bin.install "bin/sib"            # 主力バイナリ (Phase 7)
    bin.install "bin/sibyl-record"
    bin.install "bin/sibyl-log-session"
    bin.install "bin/sibyl-install"
    install_or_generate_wrapper "sibyl-bootstrap", "bootstrap"
    install_or_generate_wrapper "sibyl-intake", "intake"
    install_or_generate_wrapper "sibyl-checkout", "checkout"
    # v0.4.3 以降: sibyl-record / bootstrap / checkout / log-session / sync / sync-harness /
    # sync-user-env / analyze の全 skill を配布対象に。tarball の skills/ 全体を install。
    pkgshare.install "skills" if File.exist?("skills")
    pkgshare.install "codex-plugin" if File.exist?("codex-plugin")
    pkgshare.install "AGENTS.md" if File.exist?("AGENTS.md")
  end

  def install_or_generate_wrapper(name, subcommand)
    source = "bin/#{name}"
    if File.exist?(source)
      bin.install source
      return
    end

    (bin/name).write <<~EOS
      #!/usr/bin/env bash
      set -euo pipefail
      args=("$@")
      if [[ "#{subcommand}" == "bootstrap" || "#{subcommand}" == "intake" ]]; then
        has_agent=0
        for arg in "$@"; do
          [[ "$arg" == "--agent" || "$arg" == --agent=* ]] && has_agent=1
        done
        if [[ "$has_agent" == "0" ]]; then
          if [[ -n "${SIBYL_AGENT_TYPE:-}" && "${SIBYL_AGENT_TYPE:-}" != "auto" ]]; then agent="$SIBYL_AGENT_TYPE"
          elif [[ -n "${CLAUDECODE:-}" ]]; then agent="claude_code"
          elif [[ -n "${CURSOR_AGENT:-}" ]]; then agent="cursor"
          elif [[ -n "${QWEN_HOME:-}" ]]; then agent="qwen3_coder"
          elif [[ -n "${ANTIGRAVITY_HOME:-}" ]]; then agent="antigravity"
          else agent="codex_cli"
          fi
          args=(--agent "$agent" "$@")
        fi
      fi
      exec "#{bin}/sib" #{subcommand} "${args[@]}"
    EOS
    FileUtils.chmod 0755, bin/name
  end

  # v0.4.4: post_install は廃止。Homebrew sandbox が ~/.claude/skills/<新規ディレクトリ>
  # への mkdir を block するため、symlink 作成は brew sandbox 外の `sibyl-install --skills`
  # に委譲する。caveats で実行を促す。

  def caveats
    <<~EOS
      sibyl-record (Bash), sibyl-bootstrap/intake/checkout wrapper, sib (Bun) は brew で配備済。
      Codex CLI からは通常コマンドとして以下を実行できます:

        sibyl-bootstrap --cwd "$PWD"
        sibyl-intake --cwd "$PWD"

      全 sibyl-* skill (record / bootstrap / checkout / log-session / sync /
      sync-harness / sync-user-env / analyze) と Codex slash command plugin を
      有効化するには:

        SIBYL_BREW_SHARE=#{HOMEBREW_PREFIX}/share/sibyl sibyl-install --skills

      これで Claude Code / Codex から sibyl-bootstrap などを Skill として参照でき、
      Codex の / メニューには /sibyl-bootstrap 等が追加されます。
      (Homebrew 5.x の post_install サンドボックスは $HOME/.claude/ への mkdir を block
       するため、別コマンドに分離している。SIBYL_BREW_SHARE は brew install パス情報。)
    EOS
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/sib --version"))
    assert_match("sibyl-record", shell_output("#{bin}/sibyl-record --help 2>&1", 1))
    assert_path_exists bin/"sibyl-bootstrap"
    assert_path_exists bin/"sibyl-intake"
    assert_path_exists bin/"sibyl-checkout"
  end
end
