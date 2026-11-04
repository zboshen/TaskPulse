# Development

Requires macOS 15+ and Apple Command Line Tools (`xcode-select --install`).

```sh
./scripts/build.sh
./dist/TaskPulse.app/Contents/MacOS/TaskPulse --self-test
./scripts/package.sh
```

The build compiles arm64 and x86_64, combines them with lipo, and ad-hoc signs the app. No third-party Swift package dependencies. The Intel binary is cross-compiled, not yet tested on Intel hardware.

Policy checks cover task ordering, unread filtering, account/host isolation, date ordering, resize anchoring, movement bounds, preferred-language selection, and English translation coverage. Checks use precondition and remain active in optimized builds.

For real local state, run `--dump`. Keep its output private; do not commit or upload it.

## English and Chinese previews

```sh
./dist/TaskPulse.app/Contents/MacOS/TaskPulse --preview --language en --size medium /tmp/taskpulse-en.png
./dist/TaskPulse.app/Contents/MacOS/TaskPulse --preview --language zh-Hans --size medium /tmp/taskpulse-zh.png
```

Previews use fictional tasks only. `--language` is a process-local development override; it does not change system language preferences. Normal launches follow the first macOS preferred language: Chinese for zh, English for anything else. `--demo` opens an interactive demo, which can be exited from the menu.

## Attribution

`SideNotchShape.swift` and `NotchMotion.swift` are from [CodeNotch](https://github.com/vinzdg/codenotch), commit `6522e9f3ee0fe35d46e428b441e6e80b586eacbb`. Its original MIT notice is in `LICENSE-Codenotch`. TaskPulse provides the task filtering, desktop layout, local state adapter, and preferences.

## Connection diagnostics

The error panel and settings menu include **Copy connection diagnostics**. The report contains the failed read stage, database filename, SQLite extended code, OS errno, file readability/size, and the last successful refresh time. The same metadata is recorded in macOS Console under subsystem `site.momentu.taskpulse`, category `connection`.

Run `./scripts/test-database.sh` to exercise the actual reader in an isolated process with SQLite's global URI default disabled. It covers paths containing spaces, quotes, percent signs and non-ASCII characters, a missing history database, and recovery after restoration. This check is also part of CI.

The v0.3.1 reader explicitly enables `SQLITE_OPEN_URI`, binds the ATTACH filename, waits up to one second for SQLite locks, and retries a transient failure once after 150 ms before the next regular refresh. The screen shows an awaiting-sync state while data is unavailable.

This test reproduces a confirmed URI-configuration defect. Historical intermittent failures lacked stage/error-code diagnostics, so attributing those incidents requires a new diagnostic capture.

### Closed WAL databases and standby

On macOS SQLite 3.51.0, attaching a closed WAL-mode history database after its sidecars have been cleaned up reproduces `SQLITE_CANTOPEN` with errno 2, even though the main file is readable. TaskPulse classifies this specific signature as **Waiting for Codex**. The detector requires a valid SQLite WAL header, readable main file, and absence of both WAL and SHM files. The regular refresh resumes task display when activity recreates the sidecars. Other SQLite versions may read a closed WAL directly, so the regression accepts a successful read too.

A successful refresh clears the copied-diagnostics notice. The regression checks this through the same completion handler used by normal background refreshes.
