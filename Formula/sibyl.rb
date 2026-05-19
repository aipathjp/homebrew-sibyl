# Homebrew tap formula — aipathjp/homebrew-sibyl
#
# Phase 7 改訂: bun-compile した sib バイナリ (~63MB) も配布対象に追加。
#
# 配布対象:
#   - bin/sib                          (bun-compile Mach-O / ELF、各 arch ビルド)
#   - bin/sibyl-record / sibyl-log-session / sibyl-install
#   - skills/sibyl-record/{SKILL.md, codex-memory.md}
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
#   2. tarball に bin / skills を集約
#   3. shasum -a 256 で sha256 計算
#   4. gh release create v<VERSION> --repo aipathjp/sibyl-dist tarball
#   5. この Formula の url / sha256 / version を gh pr で aipathjp/homebrew-sibyl に更新

class Sibyl < Formula
  desc "Sibyl: AI-Path 株式会社の AI セッション記録 + transcript 統合 CLI"
  homepage "https://github.com/aipathjp/aipsibyl"
  license "Proprietary"
  version "0.4.6"

  on_macos do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.6/sibyl-0.4.6-darwin-arm64.tar.gz"
      sha256 "6f3b9a1afa707db7bc84470d5958fb476d10a7adf91a11d8f459e8cd7b7bbf63"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.6/sibyl-0.4.6-darwin-x64.tar.gz"
      sha256 "12a2ab39e1a066e668d55eb5901f4491a47b8372f41e159361df6dc2c8ca8f4b"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.6/sibyl-0.4.6-linux-arm64.tar.gz"
      sha256 "36f486c6d6979fa18567f13f42e9e8ca24de007f968aeb07e4a012f48d9c6b04"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.6/sibyl-0.4.6-linux-x64.tar.gz"
      sha256 "d8e07638e156d5cbf7a4261cd9f3d041bdc4e5b98f60b7a4e6da7c6d5ebfbd0f"
    end
  end

  def install
    bin.install "bin/sib"            # 主力バイナリ (Phase 7)
    bin.install "bin/sibyl-record"
    bin.install "bin/sibyl-log-session"
    bin.install "bin/sibyl-install"
    # v0.4.3 以降: sibyl-record / bootstrap / checkout / log-session / sync / sync-harness /
    # sync-user-env / analyze の全 skill を配布対象に。tarball の skills/ 全体を install。
    pkgshare.install "skills" if File.exist?("skills")
    pkgshare.install "AGENTS.md" if File.exist?("AGENTS.md")
  end

  # v0.4.4: post_install は廃止。Homebrew sandbox が ~/.claude/skills/<新規ディレクトリ>
  # への mkdir を block するため、symlink 作成は brew sandbox 外の `sibyl-install --skills`
  # に委譲する。caveats で実行を促す。

  def caveats
    <<~EOS
      sibyl-record (Bash) と sib (Bun) は brew で配備済。
      全 sibyl-* skill (record / bootstrap / checkout / log-session / sync /
      sync-harness / sync-user-env / analyze) を ~/.claude/skills/ に有効化するには:

        SIBYL_BREW_SHARE=#{HOMEBREW_PREFIX}/share/sibyl sibyl-install --skills

      これで Claude Code から /sibyl-bootstrap などが Skill ツール経由で呼べる。
      (Homebrew 5.x の post_install サンドボックスは $HOME/.claude/ への mkdir を block
       するため、別コマンドに分離している。SIBYL_BREW_SHARE は brew install パス情報。)
    EOS
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/sib --version"))
    assert_match("sibyl-record", shell_output("#{bin}/sibyl-record --help 2>&1", 1))
  end
end
