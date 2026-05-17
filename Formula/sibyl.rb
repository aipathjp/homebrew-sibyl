# Homebrew tap formula — aipathjp/homebrew-sibyl
#
# Phase 7 改訂: bun-compile した sib バイナリ (~63MB) も配布対象に追加。
#
# 配布対象:
#   - bin/sib                          (bun-compile Mach-O / ELF、各 arch ビルド)
#   - bin/sibyl-record / sibyl-log-session / sibyl-install
#   - skills/sibyl-record/{SKILL.md, codex-memory.md}
#   - .claude/commands/sibyl-record.md
#   - AGENTS.md
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
  version "0.4.0"

  on_macos do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.0/sibyl-0.4.0-darwin-arm64.tar.gz"
      sha256 "1ac8ab332d653cca16cb9fc36f157b74a9f02d31fc8d18a191d54d1653f4a3c1"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.0/sibyl-0.4.0-darwin-x64.tar.gz"
      sha256 "04c9671b0d675c7be2f9a13389651425aaa4c9a7d64c8f25f02ef4f851dcdd23"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.0/sibyl-0.4.0-linux-arm64.tar.gz"
      sha256 "fe758ed2d22353f4904dcd55e1ddddd49c7320e4874cf06feb5a71d820888116"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.0/sibyl-0.4.0-linux-x64.tar.gz"
      sha256 "f05d24ff66e0f7096a0d630ed7bd5283010fa1a946d132e9b1cd64e415b5d35f"
    end
  end

  def install
    bin.install "bin/sib"            # 主力バイナリ (Phase 7)
    bin.install "bin/sibyl-record"
    bin.install "bin/sibyl-log-session"
    bin.install "bin/sibyl-install"
    pkgshare.install "skills/sibyl-record/SKILL.md"
    pkgshare.install "skills/sibyl-record/codex-memory.md"
    pkgshare.install ".claude/commands/sibyl-record.md" => "claude-slash-sibyl-record.md"
    pkgshare.install "AGENTS.md" if File.exist?("AGENTS.md")
  end

  def post_install
    [
      "#{Dir.home}/.claude/skills/sibyl-record",
      "#{Dir.home}/.claude/commands",
      "#{Dir.home}/.codex/memory",
    ].each { |d| FileUtils.mkdir_p(d) }

    [
      ["#{pkgshare}/SKILL.md", "#{Dir.home}/.claude/skills/sibyl-record/SKILL.md"],
      ["#{pkgshare}/claude-slash-sibyl-record.md", "#{Dir.home}/.claude/commands/sibyl-record.md"],
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
