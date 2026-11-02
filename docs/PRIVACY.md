# Privacy and compatibility

TaskPulse is an independent community project, not affiliated with OpenAI.

## Local data access

- `~/.codex/state_5.sqlite`: conversation names and archive state.
- `~/.codex/thread_history_1.sqlite`: current turn status, start and completion times. The query selects metadata columns, not message body columns.
- `~/.codex/.codex-global-state.json`: the current account's default local host unread list. Other accounts, remote hosts, and legacy migration lists are not merged.
- `~/.codex/auth.json`: identity claims are parsed in memory to select the correct account's unread list. Tokens are not used for network requests, saved, printed, or uploaded.

Databases are opened read-only. TaskPulse does not write conversation or read-state data. Opening a conversation delegates to Codex, which records the real read state. Dismissing a result only stores a local widget preference for that turn.

## Preferences and network access

Local UserDefaults store the display, edge, position, size, Dock visibility, and dismissed-result markers. Launch at login is managed by macOS Login Items.

There is no telemetry, advertising, or custom backend. Status sync makes no network requests. New-chat and conversation buttons open local `codex://` links; Codex handles subsequent behavior. There is no auto-updater in this release. Get updates from GitHub Releases.

## Language and time

The interface uses Chinese when the first macOS preferred language is Chinese, and English for all other languages. Conversation titles are not translated. Language changes do not alter task data or the existing Asia/Shanghai date and running-task filtering rules.

## Compatibility boundaries

The adapter reads current local desktop schemas, not a stable official task-subscription API. A desktop update may change paths or fields and produce a connection error. Only the default local Codex execution host is supported. Remote tasks, standalone ChatGPT/web, and ordinary conversations using a separate ChatGPT backend are not covered.

Running tasks are limited to turns started today in Asia/Shanghai. No actual completion percentage is available, so TaskPulse does not invent one.

## Reporting a problem

Do not upload `auth.json`, databases, full logs, or raw `--dump` output. Redact private task titles from screenshots. Your macOS version, architecture, Codex version, error summary, and reproduction steps are usually enough.
