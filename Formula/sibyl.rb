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
  version "0.4.1"

  on_macos do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.1/sibyl-0.4.1-darwin-arm64.tar.gz"
      sha256 "d8a6326ba2637fe1dff608f70480656781a12ee3ce4aa6383402fb0c04647079"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.1/sibyl-0.4.1-darwin-x64.tar.gz"
      sha256 "c7b2badf9638f6661dc298393c901dd20a70bcf40778c18c443ad6d8527624d0"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.1/sibyl-0.4.1-linux-arm64.tar.gz"
      sha256 "9b39853f0e73f2b3eadd4650b95a789aa8f392d9161048a7a060cc891b3f7964"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.1/sibyl-0.4.1-linux-x64.tar.gz"
      sha256 "6cf6ff6b18f5922a351d7e29e049b40f780450222673563730c2801c2ddeb163"
    end
  end

  def install
    bin.install "bin/sib"            # 主力バイナリ (Phase 7)
    bin.install "bin/sibyl-record"
    bin.install "bin/sibyl-log-session"
    bin.install "bin/sibyl-install"
    pkgshare.install "skills/sibyl-record/SKILL.md"
    pkgshare.install "skills/sibyl-record/codex-memory.md"
    pkgshare.install "AGENTS.md" if File.exist?("AGENTS.md")
  end

  def post_install
    [
      "#{Dir.home}/.claude/skills/sibyl-record",
      "#{Dir.home}/.codex/memory",
    ].each { |d| FileUtils.mkdir_p(d) }

    # v0.4.1: skill が `/sibyl-record` slash command として自動登録されるので、
    # 同名 slash command file (~/.claude/commands/sibyl-record.md) は配布しない。
    # 旧 v0.3.x が残した既存 symlink があれば silently 削除して名前衝突を解消する。
    legacy_slash = "#{Dir.home}/.claude/commands/sibyl-record.md"
    FileUtils.rm_f(legacy_slash) if File.exist?(legacy_slash) || File.symlink?(legacy_slash)

    [
      ["#{pkgshare}/SKILL.md", "#{Dir.home}/.claude/skills/sibyl-record/SKILL.md"],
      ["#{pkgshare}/codex-memory.md", "#{Dir.home}/.codex/memory/sibyl-record.md"],
    ].each do |src, dest|
      next unless File.exist?(src)
      FileUtils.rm_f(dest)
      FileUtils.ln_s(src, dest)
    end
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/sib --version"))
    assert_match("sibyl-record", shell_output("#{bin}/sibyl-record --help 2>&1", 1))
  end
end
