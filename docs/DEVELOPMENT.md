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
