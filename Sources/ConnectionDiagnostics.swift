import Foundation
import SQLite3

// Metadata only. No task titles, conversation IDs, or authentication contents.
enum ConnectionDiagnostics {
    static func report(error: Error?, lastSuccess: Date?, failures: Int,
                       root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")) -> String {
        let now = ISO8601DateFormatter().string(from: Date())
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
        let status = error == nil ? "connected" : "unavailable"
        let failure = error as? SourceFailure
        let description = (failure?.diagnostic ?? error?.localizedDescription ?? "none")
            .replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
        let success = lastSuccess.map { ISO8601DateFormatter().string(from: $0) } ?? "none"
        var lines = [
            "TaskPulse connection diagnostics",
            "version=\(version) time=\(now)",
            "macOS=\(ProcessInfo.processInfo.operatingSystemVersionString) sqlite=\(String(cString: sqlite3_libversion()))",
            "status=\(status) consecutiveFailures=\(failures) lastSuccess=\(success)",
            description
        ]
        for name in ["state_5.sqlite", "state_5.sqlite-wal", "state_5.sqlite-shm",
                     "thread_history_1.sqlite", "thread_history_1.sqlite-wal", "thread_history_1.sqlite-shm"] {
            let path = root.appendingPathComponent(name).path
            let exists = FileManager.default.fileExists(atPath: path)
            let readable = FileManager.default.isReadableFile(atPath: path)
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            let bytes = attributes?[.size] as? NSNumber
            lines.append("\(name) exists=\(exists) readable=\(readable) bytes=\(bytes?.stringValue ?? "unknown")")
        }
        return lines.joined(separator: "\n")
    }
}
