# hooty-server — the macOS host daemon, for a machine with no graphical session.
#
# It was `coda-server` until 0.0.29, and the old name stays twice over: `coda-server` is linked
# to the same binary, so a script or a habit that says it keeps working, and
# `Formula/coda-server.rb` is this file with its class renamed (the release writes
# it), so `brew install KQAR/coda/coda-server` keeps installing and an installed one upgrades in
# place. A file rather than `formula_renames.json`: Homebrew 7 trusts a tap only for the name
# typed, and refuses a typed name that resolves to another.
#
# Binary-only, because Hooty is closed source. That is why this tap exists at all: a
# third-party tap may ship a prebuilt archive, homebrew-core may not. The tarball is cut by
# `server/release.sh` in the app repo and its version is `Version.current` — the same string
# the daemon announces in `hello`, so this formula cannot claim a version the daemon denies.
#
# `Casks/hooty.rb` next door ships the same daemon as an app in the menu bar, and that app
# carries this binary inside it. A machine wants one or the other: one UDP port, and a second
# listener would share it rather than refuse it.
class HootyServer < Formula
  desc "Host daemon for Hooty: drive the coding agents on your Mac from your phone"
  homepage "https://hooty.kqar.cc/"
  url "https://github.com/KQAR/homebrew-hooty/releases/download/v0.0.29/hooty-server-0.0.29-arm64.tar.gz"
  sha256 "c32a00e6b08a9329ec764e677743bb73298acea929595e426dbdd6dcf2d6fc9c"

  # Apple silicon only. The tarball carries one slice; an x86_64 one that nothing here can
  # execute would be a claim rather than support (`server/release.sh`), and without this a
  # `brew install` on an Intel Mac lands a binary that cannot exec.
  depends_on arch: :arm64
  # Package.swift's floor: Network.framework's QUIC is what carries the wire, and the daemon
  # is macOS-only by measurement rather than preference (ARCHITECTURE.md).
  depends_on macos: :tahoe

  # Herdr and Orca are *discovered* at runtime and never launched by coda — a machine with
  # neither still pairs and still answers. So neither is a dependency here.

  def install
    bin.install "hooty-server"
    bin.install_symlink "hooty-server" => "coda-server"
    (share/"coda").install "scrcpy-server", "LICENSE-scrcpy" if File.exist?("scrcpy-server")
    (share/"coda").install "sim-runner.tar.gz" if File.exist?("sim-runner.tar.gz")
  end

  service do
    run [opt_bin/"hooty-server", "run"]
    keep_alive true
    log_path var/"log/hooty-server.log"
    error_log_path var/"log/hooty-server.log"
    # Never root. The daemon reads this user's Keychain, ~/.coda and the agent settings
    # under ~/.claude; as root it would read the wrong ones and write files the user cannot.
    require_root false
  end

  def caveats
    <<~EOS
      Run it at login, and pair a phone:

        brew services start hooty-server
        hooty-server pair           # prints the QR the app scans

      It listens on udp/51820 and attaches to the Herdr and Orca sessions you already run —
      it never starts a session of its own. Its state, including the host key, is in ~/.coda.

      `coda-server` is the same binary, under the name it had before 0.0.29.

      Do not also install the Hooty app: it carries this binary inside it, and two listeners
      would share udp/51820 rather than refuse it.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hooty-server --help")
    assert_match version.to_s, shell_output("#{bin}/coda-server --help")
  end
end
