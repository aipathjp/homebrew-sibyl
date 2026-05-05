class Sibyl < Formula
  desc "Sibyl: AI-Path 株式会社の AI セッション記録 + Claude Code/Codex 自然言語起動"
  homepage "https://github.com/aipathjp/aipsibyl"
  url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.1.0/sibyl-0.1.0.tar.gz"
  sha256 "4f823e6b9415ef8ff2b83d0d8480d345e9bb5622f1121cff9133afb4987397ca"
  license "Proprietary"
  version "0.1.0"

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
    ].each { |d| FileUtils.mkdir_p(d) }
    pairs = [
      ["#{pkgshare}/SKILL.md",                       "#{Dir.home}/.claude/skills/sibyl-record/SKILL.md"],
      ["#{pkgshare}/claude-slash-sibyl-record.md",   "#{Dir.home}/.claude/commands/sibyl-record.md"],
      ["#{pkgshare}/codex-memory.md",                "#{Dir.home}/.codex/memories/sibyl_record.md"],
    ]
    pairs.each do |src, dst|
      FileUtils.rm_f(dst) if File.exist?(dst) || File.symlink?(dst)
      File.symlink(src, dst)
    end
  end

  def caveats
    <<~EOS
      Sibyl のセットアップを完了するには ~/.zshrc に追記:
        export SIBYL_USER_EMAIL="<your-name>@ai-path.jp"

      動作確認:
        sibyl-record "今日やったこと..."

      Claude Code / Codex は「Sibyl に記録」「checkout」等のフレーズで自動起動します。
    EOS
  end

  test do
    assert_predicate bin/"sibyl-record", :executable?
    assert_predicate bin/"sibyl-log-session", :executable?
  end
end
