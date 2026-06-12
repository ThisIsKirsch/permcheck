# permcheck

**Know the moment a trusted Mac app changes owners.**

When [Bartender was quietly sold in 2024](https://www.macrumors.com/2024/06/04/bartender-mac-app-new-owner/), it kept its screen-recording permissions and shipped an update signed by a brand-new developer ID. macOS said nothing. The only tool that noticed — MacUpdater — [shut down in January 2026](https://tidbits.com/2026/01/09/macupdater-shuts-down-leaving-users-searching-for-alternatives/).

permcheck watches the developer identity and signing certificate of every app you've installed and alerts you when one changes — especially apps holding sensitive permissions (screen recording, accessibility, full disk access). Local-only, no cloud, one-time purchase.

**→ Early access: [permcheck.com](https://permcheck.com)**

## Try the idea right now (free script)

[`permcheck.sh`](./permcheck.sh) is the core concept in ~100 lines of dependency-free bash:

```bash
curl -fsSLO https://permcheck.com/permcheck.sh && chmod +x permcheck.sh
./permcheck.sh --list   # see every app's Team ID + signing authority
./permcheck.sh          # save a baseline; run again later to diff
```

First run snapshots every app's `TeamIdentifier`; later runs flag any app whose signing identity changed — the exact signal that caught the Bartender sale. Read the source first, as you should for anything you pipe near `curl`.

The full app does this continuously from your menu bar, flags permission-holding apps, and requires no terminal.
