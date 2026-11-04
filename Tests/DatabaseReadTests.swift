import Foundation
import SQLite3

@_silgen_name("taskpulse_disable_default_uri")
func disableDefaultURI() -> Int32

func runDatabaseReadTests() throws {
    precondition(disableDefaultURI() == SQLITE_OK)
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("TaskPulse-test-\(UUID().uuidString) space # % ' 测试")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    func database(_ url: URL, sql: String) throws {
        var db: OpaquePointer?
        precondition(sqlite3_open(url.path, &db) == SQLITE_OK)
        defer { sqlite3_close(db) }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw SourceFailure(message: String(cString: sqlite3_errmsg(db)))
        }
    }
    let claims = ["https://api.openai.com/auth": ["chatgpt_account_id": "fixture", "chatgpt_user_id": "fixture"]]
    let payload = try JSONSerialization.data(withJSONObject: claims).base64EncodedString()
        .replacingOccurrences(of: "=", with: "")
    let auth = ["tokens": ["access_token": "fixture.\(payload).fixture"]]
    try JSONSerialization.data(withJSONObject: auth).write(to: root.appendingPathComponent("auth.json"))
    let global: [String: Any] = ["electron-thread-read-state-v1": ["version": 1, "unreadByIdentity": [:]]]
    try JSONSerialization.data(withJSONObject: global).write(to: root.appendingPathComponent(".codex-global-state.json"))
    try database(root.appendingPathComponent("state_5.sqlite"), sql: """
        CREATE TABLE threads (id TEXT, name TEXT, title TEXT, updated_at INTEGER,
                              rollout_path TEXT, archived INTEGER, agent_path TEXT);
        INSERT INTO threads VALUES ('fixture', 'Fixture task', '', 0, '', 0, NULL);
        """)
    let history = root.appendingPathComponent("thread_history_1.sqlite")
    try database(history, sql: """
        CREATE TABLE thread_turns (thread_id TEXT, turn_id TEXT, rollout_ordinal INTEGER,
                                   status TEXT, started_at INTEGER, completed_at INTEGER);
        INSERT INTO thread_turns VALUES ('fixture', 'turn', 1, 'inProgress',
                                         \(Int(Date().timeIntervalSince1970)), NULL);
        """)
    let reader = LocalTaskReader(root: root)
    let tasks = try reader.read()
    precondition(tasks.count == 1 && tasks[0].title == "Fixture task")
    print("PASS: real LocalTaskReader with URI defaults disabled and special path characters")

    try database(history, sql: "PRAGMA journal_mode=WAL;")
    precondition(!FileManager.default.fileExists(atPath: history.path + "-wal"))
    precondition(!FileManager.default.fileExists(atPath: history.path + "-shm"))
    precondition(ConnectionDiagnostics.isWaitingForActivity(file: history, sqliteCode: SQLITE_CANTOPEN, systemError: 2))
    do {
        // Some SQLite versions can recreate the sidecars on a read-only connection.
        let idleRead = try reader.read()
        precondition(idleRead.count == 1)
    } catch let failure as SourceFailure {
        precondition(failure.waitingForActivity && !failure.retryable)
        let report = ConnectionDiagnostics.report(error: failure, lastSuccess: nil, failures: 1, root: root)
        precondition(report.contains("status=waiting_for_activity"))
    }
    precondition(!ConnectionDiagnostics.isWaitingForActivity(file: history, sqliteCode: SQLITE_CANTOPEN, systemError: 13))
    var writer: OpaquePointer?
    precondition(sqlite3_open_v2(history.path, &writer, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK)
    precondition(sqlite3_exec(writer, "SELECT count(*) FROM thread_turns", nil, nil, nil) == SQLITE_OK)
    let activeTasks = try reader.read()
    precondition(activeTasks.count == 1)
    sqlite3_close(writer)
    try database(history, sql: "PRAGMA journal_mode=DELETE;")
    print("PASS: closed WAL is standby; activity recreating sidecars restores live reads")

    let backup = root.appendingPathComponent("history.backup")
    try FileManager.default.moveItem(at: history, to: backup)
    do {
        _ = try reader.read()
        preconditionFailure("Missing history must produce a read error")
    } catch let failure as SourceFailure {
        precondition(!FileManager.default.fileExists(atPath: history.path))
        precondition(failure.retryable)
        precondition(failure.diagnostic?.contains("file=thread_history_1.sqlite") == true)
        precondition(failure.diagnostic?.contains("errno=") == true)
        let report = ConnectionDiagnostics.report(error: failure, lastSuccess: nil, failures: 1, root: root)
        precondition(report.contains("thread_history_1.sqlite exists=false"))
        precondition(!report.contains("Fixture task") && !report.contains("access_token"))
    }
    try FileManager.default.moveItem(at: backup, to: history)
    let recovered = try reader.read()
    precondition(recovered.count == 1)
    print("PASS: missing history is not created, and the next read recovers after restoration")
}
