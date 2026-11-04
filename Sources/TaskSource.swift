import Foundation
import SQLite3

struct TaskEntry: Identifiable, Equatable, Codable {
    var id: String
    var turnID: String
    var title: String
    var source: String = "Codex"
    var status: String
    var startedAt: Double
    var completedAt: Double = 0
    var unread: Bool
    var detail: String
    var url: String
    var running: Bool { status == "inProgress" }
    var receiptKey: String { id + ":" + turnID }
}

enum TaskPolicy {
    static func visible(_ tasks: [TaskEntry], dismissed: Set<String> = []) -> [TaskEntry] {
        let running = tasks.filter(\.running).sorted { a,b in
            a.startedAt == b.startedAt ? a.id > b.id : a.startedAt > b.startedAt
        }
        let complete = tasks.filter { $0.status == "completed" && $0.unread && !dismissed.contains($0.receiptKey) }
            .sorted { a,b in a.completedAt == b.completedAt ? a.id > b.id : a.completedAt > b.completedAt }
        return Array((running + complete).prefix(5))
    }
}

struct SourceFailure: LocalizedError {
    let message: String
    var diagnostic: String? = nil
    var retryable = false
    var errorDescription: String? { message }
}
final class LocalTaskReader {
    let root: URL
    init(root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")) { self.root = root }
    func read() throws -> [TaskEntry] {
        do {
            return try readOnce()
        } catch let failure as SourceFailure where failure.retryable {
            // Reopen both databases after transient WAL/locking or file replacement races.
            Thread.sleep(forTimeInterval: 0.15)
            return try readOnce()
        }
    }

    private func readOnce() throws -> [TaskEntry] {
        let unreadIDs = try DesktopUnread.ids(root:root)
        var db: OpaquePointer?
        let catalog = root.appendingPathComponent("state_5.sqlite")
        let history = root.appendingPathComponent("thread_history_1.sqlite")
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI

        func failure(_ stage: String, file: URL) -> SourceFailure {
            // Capture SQLite's errno before filesystem probes can change process errno.
            let code = sqlite3_extended_errcode(db)
            let systemError = sqlite3_system_errno(db)
            let detail = String(cString: sqlite3_errmsg(db))
                .replacingOccurrences(of: root.path, with: "~/.codex")
                .replacingOccurrences(of: root.absoluteString, with: "file://~/.codex/")
            let primaryCode = code & 0xff
            let retryable = [SQLITE_CANTOPEN, SQLITE_BUSY, SQLITE_LOCKED, SQLITE_IOERR].contains(primaryCode)
            let diagnostic = "stage=\(stage) file=\(file.lastPathComponent) sqlite=\(code) errno=\(systemError) detail=\(detail)"
            return SourceFailure(
                message: L10n.text(stage) + " · " + file.lastPathComponent + "\n" + detail,
                diagnostic: diagnostic,
                retryable: retryable
            )
        }

        guard sqlite3_open_v2(catalog.path, &db, flags, nil) == SQLITE_OK else {
            let error = failure("打开会话数据库失败", file: catalog)
            if let db { sqlite3_close(db) }
            throw error
        }
        defer { sqlite3_close(db) }
        sqlite3_extended_result_codes(db, 1)
        sqlite3_busy_timeout(db, 1000)

        func run(_ sql: String, stage: String, file: URL) throws {
            guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
                throw failure(stage, file: file)
            }
        }

        // URI handling is explicitly enabled on the connection, including ATTACH.
        // mode=ro also prevents creating an empty history database during rotation.
        var attach: OpaquePointer?
        guard sqlite3_prepare_v2(db, "ATTACH DATABASE ? AS history", -1, &attach, nil) == SQLITE_OK else {
            throw failure("打开任务历史数据库失败", file: history)
        }
        defer { sqlite3_finalize(attach) }
        let uri = history.absoluteString + "?mode=ro"
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        guard sqlite3_bind_text(attach, 1, uri, -1, transient) == SQLITE_OK,
              sqlite3_step(attach) == SQLITE_DONE else {
            throw failure("打开任务历史数据库失败", file: history)
        }
        // Release this statement before starting the cross-database read transaction.
        sqlite3_reset(attach)
        try run("PRAGMA query_only=ON", stage: "初始化只读连接失败", file: catalog)
        try run("BEGIN", stage: "开始读取任务失败", file: catalog)
        defer { try? run("ROLLBACK", stage: "结束读取任务失败", file: catalog) }
        let sql = """
        WITH latest AS (
          SELECT *, ROW_NUMBER() OVER(PARTITION BY thread_id ORDER BY rollout_ordinal DESC) AS n
          FROM history.thread_turns
        )
        SELECT t.id, l.turn_id, COALESCE(NULLIF(t.name,''), t.title), l.status,
               COALESCE(l.started_at, t.updated_at), COALESCE(l.completed_at,0),
               0, t.rollout_path
        FROM threads t JOIN latest l ON t.id=l.thread_id AND l.n=1
        WHERE t.archived=0 AND (t.agent_path IS NULL OR t.agent_path='/root')
          AND l.status IN ('inProgress','completed')
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw failure("读取任务结构失败", file: history)
        }
        defer { sqlite3_finalize(stmt) }
        func str(_ i: Int32) -> String { sqlite3_column_text(stmt,i).map { String(cString:$0) } ?? "" }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let today = calendar.startOfDay(for: Date()).timeIntervalSince1970
        var tasks: [TaskEntry] = []
        var code = sqlite3_step(stmt)
        while code == SQLITE_ROW {
            let id = str(0), status = str(3), started = sqlite3_column_double(stmt,4)
            // Match the app's active-turn state, restricted to today's turns (Asia/Shanghai).
            if (status == "inProgress" && started >= today) || (status == "completed" && unreadIDs.contains(id)) {
                let title = str(2).components(separatedBy: .newlines).first ?? L10n.text("Codex 任务")
                tasks.append(TaskEntry(id:id,turnID:str(1),title:title,status:status,startedAt:started,
                    completedAt:sqlite3_column_double(stmt,5),unread:unreadIDs.contains(id),
                    detail:status == "inProgress" ? L10n.text("正在执行") : L10n.text("完成 · 未读"),url:"codex://threads/\(id)"))
            }
            code = sqlite3_step(stmt)
        }
        guard code == SQLITE_DONE else { throw failure("读取任务数据失败", file: history) }
        return tasks
    }
}
