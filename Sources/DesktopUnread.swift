import Foundation
import CryptoKit

// The desktop app's UI read-state store, scoped by identity and execution host.
// Never union identities, hosts, legacy migrations, or SQLite historical receipts.
enum DesktopUnread {
    static func hash(_ values: [Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject:values,options:[.withoutEscapingSlashes])
        return SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()
    }
    static func ids(root:URL) throws -> Set<String> {
        let global = try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent(".codex-global-state.json"))) as? [String:Any] ?? [:]
        let auth = try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("auth.json"))) as? [String:Any] ?? [:]
        guard let tokens = auth["tokens"] as? [String:Any],let token = tokens["access_token"] as? String,
              let claims = claims(token),let ns = claims["https://api.openai.com/auth"] as? [String:Any],
              let account = ns["chatgpt_account_id"] as? String,
              let user = (ns["chatgpt_user_id"] ?? ns["user_id"]) as? String else {
            throw SourceFailure(message:L10n.text("无法识别当前应用账户，未读状态暂不可用"))
        }
        let identity = try hash(["chatgpt",account,user])
        let host = "local:" + (try hash(["local","local",NSNull()]))
        return try ids(global:global,identity:identity,host:host)
    }
    static func ids(global:[String:Any],identity:String,host:String) throws -> Set<String> {
        guard let state = global["electron-thread-read-state-v1"] as? [String:Any],
              state["version"] as? Int == 1,
              let identities = state["unreadByIdentity"] as? [String:Any] else {
            throw SourceFailure(message:L10n.text("当前应用未读状态尚不可用"))
        }
        let hosts = identities[identity] as? [String:Any] ?? [:]
        return Set(hosts[host] as? [String] ?? [])
    }
    private static func claims(_ token:String) -> [String:Any]? {
        let segments = token.split(separator:".")
        guard segments.count > 1 else { return nil }
        var base64 = String(segments[1]).replacingOccurrences(of:"-",with:"+").replacingOccurrences(of:"_",with:"/")
        base64 += String(repeating:"=",count:(4-base64.count%4)%4)
        guard let data = Data(base64Encoded:base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with:data)) as? [String:Any]
    }
}
