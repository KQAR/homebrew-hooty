# homebrew-hooty

Homebrew tap for **Hooty** — drive the coding agents on your Mac from your phone.

Hooty was called coda until 0.0.29, and this tap was `KQAR/homebrew-coda`. The old names
still work: GitHub redirects the old repository, `cask_renames.json` and
`formula_renames.json` map `coda` → `hooty` and `coda-server` → `hooty-server`, so
`brew install --cask KQAR/coda/coda` installs Hooty, and an installed `coda` or
`coda-server` is migrated on the next `brew update`. `coda-server` is linked to the same
binary as `hooty-server`. An app installed as `coda.app` updates itself in place and keeps
that file name; `brew upgrade --cask --greedy hooty` moves it to `Hooty.app`.

The same daemon ships two ways, and a machine wants one of them. The **app** lives in the
menu bar and carries the CLI inside it, so it is a complete install on its own. The **CLI**
is for a machine with no graphical session, where a status item cannot run.

```sh
brew install --cask KQAR/hooty/hooty
```

```sh
brew install KQAR/hooty/hooty-server
brew services start hooty-server
hooty-server pair           # prints the QR the app scans
```

Run one or the other, not both: one UDP port, and the app will tell you whose it is.

Both are named through the tap rather than tapped first. `brew install` taps on demand for a
fully-qualified name, and Homebrew 7 refuses to load a formula or a cask from a tap it was
not told to trust — naming it in full is that permission, and `brew trust KQAR/hooty` once is
the only other way.

Without Homebrew — installs the CLI to `~/.local/bin`, registers a LaunchAgent, nothing runs
as root, and it refuses rather than quietly producing a second copy:

```sh
curl -fsSL https://github.com/KQAR/homebrew-hooty/releases/latest/download/install.sh | sh
```

Options through that pipe need `sh -s --`, since the script is on sh's stdin and not in its
arguments: `| sh -s -- --dry-run`, `--force`, `--no-service`, `--uninstall`.

## Upgrading and removing

The app updates itself (Sparkle), so `brew upgrade` leaves it alone unless asked:
`brew upgrade --cask --greedy hooty` replaces it; quit it from its menu first, which the
cask's `uninstall quit:` does for you. `brew upgrade hooty-server` restarts the daemon under
`brew services` on its own.

Uninstalling leaves `~/.coda` — the host key, the phones' enrolments, the tunnel key — in
place, because throwing it away means pairing every phone again. `brew uninstall --zap
--cask hooty` is the deliberate way to take it with you.

## What it does

The daemon attaches to the [Herdr](https://herdr.dev) and Orca sessions already running on
your machine and offers them to the phone over a pinned QUIC link on `udp/51820`. It never
starts a session of its own, and there is no cloud hop: the phone talks to your machine, over
your LAN, over Tailscale, or through Hooty's own tunnel when you turn it on. Pairing is a QR —
a single-use 60-second token plus the host key fingerprint — and a device is taken back with
`hooty-server revoke`.

## Requirements

- macOS 26 or newer, Apple silicon. An x86_64 slice that nobody here can execute would be a
  claim rather than support, so there is not one, and an Intel Mac is refused out loud.
- Herdr or Orca, if you want panes — a machine with neither still pairs and still answers.

## Notes

Hooty is closed source, so this tap ships prebuilt binaries rather than a source build.
Third-party taps may do that; homebrew-core may not, which is the whole reason this
repository exists.

Builds up to and including 0.0.2 are signed ad-hoc rather than with a Developer ID. Two
consequences, both temporary. macOS asks for local network permission again after every
upgrade. And the app arrives quarantined however you install it, which Gatekeeper refuses as
"damaged" — so clear the flag before you open it:

```sh
xattr -dr com.apple.quarantine /Applications/coda.app
```

Homebrew is not the one setting it: 7.0 stopped quarantining what it installs and deleted
`--no-quarantine` with it. macOS is, carrying the flag out of the disk image the cask
downloads. A Developer ID signature is what removes the instruction, not a brew option.

From 0.0.3 every build is signed with a Developer ID and notarised — the disk image stapled —
so none of the above applies to it.
