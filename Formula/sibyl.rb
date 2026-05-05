class Sibyl < Formula
  desc "Sibyl: AI-Path 株式会社の AI セッション記録 + Claude Code/Codex 自然言語起動 + sib CLI"
  homepage "https://github.com/aipathjp/aipsibyl"
  url "https://github.com/aipathjp/sibyl-dist/releases/download/v0.3.2/sibyl-0.3.2.tar.gz"
  sha256 "510a3a5adb1ec21265bee1de79edd5cc4c410ceafd6a1af11765589357afa61f"
  license "Proprietary"
  version "0.3.2"

  depends_on "python@3.12"

  def install
    bin.install "bin/sibyl-record"
    bin.install "bin/sibyl-log-session"
    bin.install "bin/sibyl-install"
    bin.install "bin/sib"
    pkgshare.install "skills/sibyl-record/SKILL.md"
    pkgshare.install "skills/sibyl-record/codex-memory.md"
    pkgshare.install ".claude/commands/sibyl-record.md" => "claude-slash-sibyl-record.md"
    pkgshare.install "AGENTS.md"
  end

  def caveats
    <<~EOS
      Sibyl のセットアップ (brew install 後に 1 度だけ):

        1. ~/.zshrc に追記:
             export SIBYL_USER_EMAIL="<your-name>@ai-path.jp"

        2. 自然言語起動 (Claude Code skill / slash + Codex memory) を有効化:
             SIBYL_BREW_SHARE=#{HOMEBREW_PREFIX}/share/sibyl sibyl-install

        3. 動作確認:
             sibyl-record "今日やったこと..."
             sib --version

      → 以後 Claude Code / Codex で「Sibyl に記録」「checkout」等で自動起動。
    EOS
  end

  test do
    assert_predicate bin/"sibyl-record", :executable?
    assert_predicate bin/"sibyl-log-session", :executable?
    assert_predicate bin/"sibyl-install", :executable?
    assert_predicate bin/"sib", :executable?
    assert_match "0.3.2", shell_output("#{bin}/sib --version")
  end
end
