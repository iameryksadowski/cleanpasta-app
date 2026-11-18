# Changelog

All notable changes to Cleanpasta. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/). The top version is the app's version (`scripts/build-app.sh` reads it); "unreleased" becomes the date on the day of the release.

## [1.2.0] - unreleased

Includes the fixes prepared as 1.1.1, which was never released.

### Changed

- **Cleanpasta stands on its own.** The app is Cleanpasta and "Eryk Sadowski" is its signature in the About window and footers. The About window is simpler, the app icon is the green clipboard and the menu bar icon a plain clipboard.
- **New identifiers.** Bundle identifier `com.eryksadowski.cleanpasta` (the command line tool: `com.eryksadowski.cleanpasta.cli`), signing certificate "Eryk Sadowski", repository `iameryksadowski/cleanpasta-app`. The update from 1.1.x installs as usual (it is signed with the same update key). Because the identifier and the signature change, it starts like a new installation: allow Accessibility once more, set your shortcuts and options again and turn Open at login back on in Settings if you use it.
- **Updates come from `cleanpasta.eryksadowski.workers.dev`** (Cloudflare), like the other apps by Eryk Sadowski. Every version is still published on GitHub Releases too.
- **The command line tool lives in `~/.local/bin`**, like the other apps by Eryk Sadowski. A `cleanpasta` link from 1.1.x in `/opt/homebrew/bin` or `/usr/local/bin` moves there by itself; the old link is removed only once a new Terminal finds `~/.local/bin`, and Settings show the command that adds it to the PATH.
- Windows preview: identifier `com.eryksadowski.cleanpasta`, settings in `%APPDATA%\cleanpasta`, command line tool installed to `%LOCALAPPDATA%\Cleanpasta\bin`, settings window without the wordmark; starting the app again opens its settings.

### Fixed

- **Slack: no more double blank lines.** After a bullet list (most visibly one with a single point) Slack added a second empty line. Bullet lists are no longer wrapped in an extra block, so every gap is one blank line; Apple Mail pastes the result exactly as before.
- Preserve line breaks, blank lines and indentation in HTML and fenced Markdown code blocks; inline code stays literal instead of becoming bold, italic or a link.
- Keep explicit Markdown numbering, HTML list item values and all descendants of mixed nested lists.
- Detect standalone Markdown links, italic text and code, convert simple pipe tables, and keep rules inside fenced code when using `--body`.
- Reject invalid UTF-8 from standard input with exit code 1, matching file input.
- Preserve unrelated command line tools when installing the CLI.
- Validate and stage downloaded apps before replacing an installation; releases now require a persistent signing identity instead of silently falling back to ad-hoc signing.

### Removed

- **Raycast commands** and the Raycast section in Settings. Use the shortcuts, the menu bar icon or the `cleanpasta` command line tool (`--paste`, `--repair`).
- The `cleanpasta://` links and the older links from 1.0.x; on Windows the matching deep links. Scripts and launchers use the `cleanpasta` command line tool.

## [1.1.0] - 2026-10-15

### Changed

- **New name: Cleanpasta.** The app, its menu, the command line tool (`cleanpasta`), the links (`cleanpasta://`) and the repository carry the new name. An installed 1.0.x updates in place: on the first launch it renames itself to Cleanpasta.app, moves the command line tool link and keeps the settings, shortcuts and the Accessibility permission.
- **Numbered points are pasted as plain paragraphs** ("1. ...") without an indent, with a blank line after each, so the numbering stays exactly as written. Only bullet points become a list, right below a line that ends with a colon. A greeting on the first line gets its own paragraph.
- **Raycast** has its own section in Settings: turn on Raycast commands to add Paste Clean, Repair Clipboard, Settings and About to Raycast (one import step in Raycast); turn them off to see how to remove them.

### Added

- Every shortcut has a button that removes it; a command without a shortcut still works from the menu bar icon.
- The cleaning logic now lives in this repository (`converter/`, with its unit tests and paste tests in the WebKit editor used by Apple Mail).

## [1.0.1] - 2026-10-01

### Added

- **About** window in the menu bar menu: the tool, its version and build, the author (Eryk Sadowski) and links to the source code, changelog and license.
- **Add to Raycast** in Settings > General: saves Paste Clean, Repair Clipboard, Settings and About as Raycast Quicklinks (a file in Downloads) and opens Raycast for its Import Quicklinks command; give them Raycast hotkeys if you like.
- A link that opens the About window.
- The menu bar menu shows the installed version at the bottom, so you can see at a glance that an update went through.

### Changed

- After an update that takes away the Accessibility permission, the app opens its settings with the one-click way back.
- A paste started from a link (Raycast, scripts) waits a moment longer, so the launcher can close and the target app comes back first.

## [1.0.0] - 2026-09-29

### Added

- Menu bar app: **Paste Clean** cleans the clipboard and pastes it into the app you are in; **Repair Clipboard** cleans it in place for a manual Cmd+V. Both with global shortcuts (Paste Clean: Control+Option+Command+V).
- Keeps bold, italic, underline, links, line breaks, non-breaking spaces, lists and simple tables; drops backgrounds, colors and fonts. Markdown becomes formatted text. Em and en dashes become "-", typographic quotes become " and '.
- Settings: shortcuts, dashes, quotes, font size (12 px by default, like Apple Mail), open at login, confirmation, updates, Accessibility status. The Dock icon shows only while the settings window is open.
- Command line tool for Terminal, scripts and AI assistants, installed from the settings.
- In-app updates with the changelog, after the user agrees.
- Paste, repair and settings links for Raycast and scripts.
