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

struct SourceFailure: LocalizedError { let message: String; var errorDescription: String? { message } }
final class LocalTaskReader {
    let root: URL
    init(root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")) { self.root = root }
    func read() throws -> [TaskEntry] {
        let unreadIDs = try DesktopUnread.ids(root:root)
        var db: OpaquePointer?
        let path = root.appendingPathComponent("state_5.sqlite").path
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            if let db { sqlite3_close(db) }
            throw SourceFailure(message: "无法读取 Codex 数据库，请检查数据目录")
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 250)
        func run(_ sql: String) throws {
            guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
                throw SourceFailure(message: String(cString: sqlite3_errmsg(db)))
            }
        }
        // SQLite URI prevents ATTACH from creating or writing a missing history store.
        let history = root.appendingPathComponent("thread_history_1.sqlite")
        guard FileManager.default.fileExists(atPath: history.path) else { throw SourceFailure(message: "缺少 Codex 任务历史库") }
        let uri = history.absoluteString + "?mode=ro"
        try run("ATTACH DATABASE '\(uri.replacingOccurrences(of: "'", with: "''"))' AS history")
        try run("PRAGMA query_only=ON")
        try run("BEGIN")
        defer { try? run("ROLLBACK") }
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
            throw SourceFailure(message: "Codex 数据结构不兼容：" + String(cString: sqlite3_errmsg(db)))
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
                let title = str(2).components(separatedBy: .newlines).first ?? "Codex 任务"
                tasks.append(TaskEntry(id:id,turnID:str(1),title:title,status:status,startedAt:started,
                    completedAt:sqlite3_column_double(stmt,5),unread:unreadIDs.contains(id),
                    detail:status == "inProgress" ? "正在执行" : "完成 · 未读",url:"codex://threads/\(id)"))
            }
            code = sqlite3_step(stmt)
        }
        guard code == SQLITE_DONE else { throw SourceFailure(message: "任务读取中断") }
        return tasks
    }
}
