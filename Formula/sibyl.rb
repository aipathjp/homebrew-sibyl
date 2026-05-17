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
  version "0.4.3"

  on_macos do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.3/sibyl-0.4.3-darwin-arm64.tar.gz"
      sha256 "a8ac5b3ff84854dbf360fef84d0838b8be351ddb17f84d8908c4f9ce989f8d73"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.3/sibyl-0.4.3-darwin-x64.tar.gz"
      sha256 "e4fce4cd77b6d7e3cc7d8bf05335756b8d99ad7671bc0fafd9629ef9b78f5639"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.3/sibyl-0.4.3-linux-arm64.tar.gz"
      sha256 "501432a43cb3be36495617b71cf2349bb21968398a346dc34ea849a9c795e930"
    end
    on_intel do
      url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.4.3/sibyl-0.4.3-linux-x64.tar.gz"
      sha256 "53ebd1d861e70ad86bc062dce479f5c816e92b30810879c4fa6cb744375b5197"
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

  def post_install
    # v0.4.1: 旧 v0.3.x が残した /sibyl-record slash command symlink を silently 削除。
    # skill が `/sibyl-record` として自動登録されるので、同名 slash command file は不要。
    legacy_slash = "#{Dir.home}/.claude/commands/sibyl-record.md"
    FileUtils.rm_f(legacy_slash) if File.exist?(legacy_slash) || File.symlink?(legacy_slash)

    # v0.4.3: 全 sibyl-* skill を ~/.claude/skills/<name>/ に symlink。
    # 既存ファイル/symlink は強制上書き (常に tap の最新を指す)。
    skills_root = "#{pkgshare}/skills"
    if File.directory?(skills_root)
      Dir["#{skills_root}/sibyl-*"].each do |skill_dir|
        next unless File.directory?(skill_dir)
        skill_name = File.basename(skill_dir)
        dest_dir = "#{Dir.home}/.claude/skills/#{skill_name}"
        FileUtils.mkdir_p(dest_dir)
        Dir["#{skill_dir}/*.md"].each do |src|
          dest = "#{dest_dir}/#{File.basename(src)}"
          FileUtils.rm_f(dest)
          FileUtils.ln_s(src, dest)
        end
      end
    end

    # codex memory (sibyl-record/codex-memory.md → ~/.codex/memory/sibyl-record.md)
    FileUtils.mkdir_p("#{Dir.home}/.codex/memory")
    codex_src = "#{pkgshare}/skills/sibyl-record/codex-memory.md"
    if File.exist?(codex_src)
      FileUtils.rm_f("#{Dir.home}/.codex/memory/sibyl-record.md")
      FileUtils.ln_s(codex_src, "#{Dir.home}/.codex/memory/sibyl-record.md")
    end
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/sib --version"))
    assert_match("sibyl-record", shell_output("#{bin}/sibyl-record --help 2>&1", 1))
  end
end
