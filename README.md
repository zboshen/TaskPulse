<p align="center"><img src="assets/icon.png" width="112" alt="TaskPulse app icon"></p>
<h1 align="center">TaskPulse</h1>
<p align="center"><b>Let Codex work. Keep its progress in the corner of your eye.</b><br>A lightweight Codex desktop widget &amp; task tracker for macOS.</p>
<p align="center">
<a href="https://github.com/zboshen/TaskPulse/releases/latest/download/TaskPulse.dmg">Download for macOS</a> ·
<a href="https://github.com/zboshen/TaskPulse/releases">Releases</a> ·
<a href="https://github.com/zboshen/TaskPulse/issues">Feedback</a> ·
<a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center"><img src="assets/preview.png" width="380" alt="TaskPulse English demo: running Codex tasks and unread completed results"></p>

Codex has a few tasks running. You have something else to do. **TaskPulse** keeps a small card at your screen edge so you can see what is still working and which results are ready to read, without repeatedly switching back to the main window.

A native **Codex desktop widget**, **task tracker**, and **task monitor** for your Mac. Inspired by [CodeNotch](https://github.com/vinzdg/codenotch), with its MIT-licensed edge shape and spring animations reused with attribution. TaskPulse focuses that interaction on one thing: following your local Codex tasks.

## Small by design

- **Native SwiftUI + AppKit.** No Electron or embedded browser runtime.
- **No third-party Swift package dependencies.** Built with system frameworks and SQLite.
- **No separate backend or API key setup.** Read-only local status sync every two seconds.
- **No ads or telemetry.** Local login identity claims are used only to select the right account's unread list; tokens are never sent or uploaded.
- **A menu bar companion.** Hidden from the Dock by default, with optional launch at login.

The initial download is around **2 MB**. “Lightweight” describes the implementation and dependency footprint; we do not claim unmeasured CPU, memory, or battery figures.

## Just the tasks that need your attention

| Feature | How it works |
|---|---|
| In progress | Turns started today in Asia/Shanghai that are still running, newest starts first |
| Completed | Only unread results for the current account and local host, latest completion first; read results disappear |
| Up to five tasks | Running work takes priority; unread completions fill the remaining slots |
| New chat | Open a blank Codex chat from the header button |
| Multiple displays | Choose the primary display or a specific secondary display, with left or right edge docking |
| Drag to move | Move the card vertically by its title; position is remembered |
| Drag to resize | Pull the inner edge; text, spacing, and cards adapt to the width |
| Content size | Small, Medium, and Large presets, with scrolling for tall content |
| Launch at login | Optional, managed by macOS Login Items |
| Hide from Dock | Optional, enabled by default; the menu bar icon stays available |

## English or Chinese, automatically

TaskPulse follows your macOS preferred language: **Chinese if your first preferred language is Chinese, English otherwise**. French, Japanese, German, and other languages use the English interface for now.

Sections, menus, tooltips, accessibility labels, status messages, and elapsed time are localized. Your actual conversation titles stay in their original language. If macOS asks you to restart the app after a language change, quit and reopen TaskPulse. No language switch needs to be configured inside the widget.

## Download and install

**macOS 15 or later. Universal: Apple Silicon + Intel.** The Intel binary is cross-compiled but has not yet been verified on Intel hardware.

1. [Download TaskPulse.dmg](https://github.com/zboshen/TaskPulse/releases/latest/download/TaskPulse.dmg). A ZIP and SHA-256 checksums are also available on [Releases](https://github.com/zboshen/TaskPulse/releases).
2. Open the DMG and drag **TaskPulse.app** into **Applications**.
3. Launch it and use the header settings to choose your display, docking edge, and content size. Enable launch at login after installation if you want it.

The app is ad-hoc signed and **not notarized by Apple**. macOS may block the first launch. Only if you trust the download from this repository, use the system's Privacy & Security flow to allow it. We do not provide scripts that automatically bypass security checks.

## Stay in the loop

Choose **Watch → Custom → Releases** to subscribe to new versions. **Star** the repository to keep it handy, or [follow @zboshen](https://github.com/zboshen) for future projects.

An [Atom release feed](https://github.com/zboshen/TaskPulse/releases.atom) is available for feed readers. This version does not include an auto-updater.

## A few useful details

Hover to expand. Pin the card to keep it open, or unpin it to collapse when the pointer leaves. Click a task to open the original conversation; Codex records its actual read state. The × button only dismisses the current result inside TaskPulse. A later completed turn can appear again.

**Compatibility:** TaskPulse is an independent community project, not affiliated with OpenAI. The adapter targets the default local Codex execution host. It does not cover remote tasks, standalone ChatGPT/web, or ordinary chats using a separate ChatGPT backend. Local schemas may change with Codex updates; please open an Issue if something stops working. Execution filtering and displayed dates currently use **Asia/Shanghai**; interface language does not change that rule.

[Privacy and data sources](docs/PRIVACY.md) · [Build and verify](docs/DEVELOPMENT.md)

Looking for a **Codex 桌面组件 / 任务组件 / 任务进度侧边栏**? See the [Chinese introduction](README.zh-CN.md).

## Credits and license

Thanks to [vinzdg/codenotch](https://github.com/vinzdg/codenotch) for exploring this screen-edge interaction. The edge shape and spring animations come from CodeNotch; its original notice is preserved in [LICENSE-Codenotch](LICENSE-Codenotch).

TaskPulse is open source under [MIT](LICENSE). Contributions and feedback are welcome.
