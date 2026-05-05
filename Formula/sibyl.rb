class Sibyl < Formula
  desc "Sibyl: AI-Path 株式会社の AI セッション記録 + Claude Code/Codex 自然言語起動"
  homepage "https://github.com/aipathjp/aipsibyl"
  url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.1.1/sibyl-0.1.1.tar.gz"
  sha256 "adc7c0a53a22cc5e45a327a538a6fb52ca3fd04b3b48f49c6d87f95091bea065"
  license "Proprietary"
  version "0.1.1"

  depends_on "python@3.12"

  def install
    bin.install "bin/sibyl-record"
    bin.install "bin/sibyl-log-session"
    bin.install "bin/sibyl-install"
    pkgshare.install "skills/sibyl-record/SKILL.md"
    pkgshare.install "skills/sibyl-record/codex-memory.md"
    pkgshare.install ".claude/commands/sibyl-record.md" => "claude-slash-sibyl-record.md"
    pkgshare.install "AGENTS.md"
  end

  def post_install
    [
      "#{Dir.home}/.claude/skills/sibyl-record",
      "#{Dir.home}/.claude/commands",
      "#{Dir.home}/.codex/memories",
    ].each do |d|
      begin
        FileUtils.mkdir_p(d)
      rescue StandardError => e
        ohai "skip mkdir #{d}: #{e.message}"
      end
    end

    pairs = [
      ["#{pkgshare}/SKILL.md",                       "#{Dir.home}/.claude/skills/sibyl-record/SKILL.md"],
      ["#{pkgshare}/claude-slash-sibyl-record.md",   "#{Dir.home}/.claude/commands/sibyl-record.md"],
      ["#{pkgshare}/codex-memory.md",                "#{Dir.home}/.codex/memories/sibyl_record.md"],
    ]
    pairs.each do |src, dst|
      begin
        FileUtils.rm_f(dst)
        File.symlink(src, dst) if File.exist?(src)
        ohai "linked #{dst} -> #{src}"
      rescue StandardError => e
        ohai "skip link #{dst}: #{e.message}"
      end
    end
  end

  def caveats
    <<~EOS
      Sibyl のセットアップを完了するには ~/.zshrc に追記:
        export SIBYL_USER_EMAIL="<your-name>@ai-path.jp"

      動作確認:
        sibyl-record "今日やったこと..."

      Claude Code / Codex は「Sibyl に記録」「checkout」等のフレーズで自動起動します。

      自然言語起動の symlink が反映されない場合は手動で再実行:
        brew postinstall sibyl
    EOS
  end

  test do
    assert_predicate bin/"sibyl-record", :executable?
    assert_predicate bin/"sibyl-log-session", :executable?
  end
end
