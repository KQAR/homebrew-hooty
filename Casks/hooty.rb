# coda — the macOS host daemon, in the menu bar.
#
# This is `cask.rb.in`: `server/release.sh` fills in the version, the url and the sha256 and
# writes the result to `server/dist/coda.rb`, which is what goes into `Casks/coda.rb` in the
# tap. It is templated *here*, beside the app, for the same reason `install.sh.in` is: the
# caveats and the `zap` list describe what this app does to the machine, and they have to
# change in the commit that changes it, not in another repository afterwards.
#
# A cask rather than a formula because this is an app bundle. `Formula/coda-server.rb` stays
# where it is and ships the CLI — the two are the same daemon, and a machine may want either.
#
# The stanza order below is Homebrew's, not a preference: `brew style`'s Cask/StanzaOrder cop
# rejects any other, and `livecheck` in particular belongs above `depends_on`.
cask "hooty" do
  version "0.0.28"
  sha256 "cefa9ce776b3f1dffc1516e48ae80629f731c78e5115f30aab027696e9f4903d"

  # `#{version}` rather than the whole URL spelled out: `brew audit` reads a url that does not
  # mention the version as an *unversioned* one and asks for `sha256 :no_check`, which would
  # mean shipping an image nothing checks. The tag is substituted whole because a packaging
  # revision moves it and not the version (`server/release.sh --revision=`).
  url "https://github.com/KQAR/homebrew-coda/releases/download/v0.0.28/coda-#{version}.dmg"
  name "coda"
  # No platform in a cask's description — `brew style`'s Cask/Desc cop rejects "Mac", which
  # is how the formula next door words the same sentence.
  desc "Drive your coding agents from your phone"
  homepage "https://github.com/KQAR/homebrew-coda"

  # A packaging revision is a suffix on the *tag*, never on the version — the same binary
  # under a new tag is what `server/release.sh --revision=` cuts, because a published asset is
  # never replaced. Homebrew's default check reads the latest release's tag literally and then
  # reports `0.0.1` as out of date against `0.0.1-3`; this regex drops the suffix so a
  # revision is invisible here, exactly as it is to `brew info`.
  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)*)(?:-\d+)?$/i)
  end

  # Package.swift's floor. Network.framework's QUIC is what carries the wire, and the daemon
  # is macOS-only by measurement rather than preference (ARCHITECTURE.md). A bare symbol
  # means "this or newer"; the `">= :tahoe"` string form is deprecated and Homebrew says so.
  #
  # Apple silicon, because the image carries one slice: an x86_64 one that nothing here can
  # execute would be a claim rather than support (`server/release.sh`). Without this, an Intel
  # Mac installs an app that will not launch.
  # The app updates itself (Sparkle, `Updater`), so `brew upgrade` leaves it alone unless asked
  # with `--greedy` — otherwise the two would take turns replacing one bundle, and Homebrew's
  # idea of the installed version would be whichever of them went last.
  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "coda.app"

  # Quit it before the bundle is replaced. A running copy holds udp/51820 and the keychain
  # its TLS key lives in; swapping the bundle underneath leaves a process whose code is no
  # longer on disk. And the login item is the app's own **Start at Login** switch
  # (`SMAppService.mainApp`), which would otherwise be left pointing at an app that is gone.
  uninstall quit:       "tech.kqar.coda.server",
            login_item: "coda"

  # `~/.coda` is the host key, the phones' enrolments and the tunnel key — everything a
  # paired phone pinned. It is in `zap`, which is opt-in (`brew uninstall --zap`), and not in
  # `uninstall`, precisely because throwing it away means pairing every phone again.
  zap trash: [
    "~/.coda",
    "~/Library/Preferences/tech.kqar.coda.server.plist",
  ]

  caveats do
    <<~EOS
      Open it. It lives in the menu bar and has no Dock icon; use **Pairing code…** in
      its menu and scan that with coda on your phone.

      It serves udp/51820 and attaches to the Herdr and Orca sessions you already run — it
      never starts one of its own. Its state, including the host key, is in ~/.coda.

      You do not also need `coda-server`: this app is the daemon. That formula is for a machine
      with no graphical session, where a status item cannot run. Do not run both — one port,
      one daemon. Each looks before it binds: the app tells you whose port it is and offers
      to take it over, and `coda-server run` waits (or, in a terminal, refuses).
    EOS
  end
end
