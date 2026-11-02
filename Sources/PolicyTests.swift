import Foundation
func runPolicyTests() {
    func task(_ n:Int,_ status:String = "inProgress",unread:Bool = false) -> TaskEntry {
        TaskEntry(id:String(n),turnID:"turn",title:"task",status:status,startedAt:Double(n),completedAt:Double(n),unread:unread,detail:"",url:"")
    }
    let read = task(99,"completed"), unread = task(50,"completed",unread:true)
    precondition(TaskPolicy.visible([read]).isEmpty,"read completion must disappear")
    precondition(TaskPolicy.visible([unread]).count == 1)
    precondition(TaskPolicy.visible((1...6).map { task($0) } + [unread]).map(\.id) == ["6","5","4","3","2"])
    precondition(TaskPolicy.visible([task(1),task(2),unread,read]).map(\.id) == ["2","1","50"])
    precondition(TaskPolicy.visible([unread],dismissed:[unread.receiptKey]).isEmpty)
    var next = unread; next.turnID = "next"
    precondition(TaskPolicy.visible([next],dismissed:[unread.receiptKey]).count == 1,"new turn must become visible again")
    precondition(TaskPolicy.visible([task(1,"failed",unread:true),task(2,"interrupted",unread:true)]).isEmpty)
    let old = task(10,"completed",unread:true)
    let recent = task(20,"completed",unread:true)
    precondition(TaskPolicy.visible([old,unread,recent]).map(\.id) == ["50","20","10"],"completion dates descending")
    let global: [String:Any] = ["electron-thread-read-state-v1":["version":1,
        "unreadByIdentity":["current":["local":[],"remote":["old-remote"]],"other":["local":["other-account"]]],
        "legacyMigration":["unreadThreadIdsByHostId":["local":["stale"]]]]]
    precondition(try! DesktopUnread.ids(global:global,identity:"current",host:"local").isEmpty,
           "historical/other-account/remote unread must never leak into the current UI")
    var changed = global
    changed["electron-thread-read-state-v1"] = ["version":1,"unreadByIdentity":["current":["local":["new"]]]]
    precondition(try! DesktopUnread.ids(global:changed,identity:"current",host:"local") == ["new"])
    precondition(try! DesktopUnread.ids(global:global,identity:"current",host:"local").isEmpty,"reading removes it")
    precondition(SidebarSizing.resized(start:346,translation:-100,rightEdge:true,available:800) == 446)
    precondition(SidebarSizing.resized(start:346,translation:100,rightEdge:false,available:800) == 446)
    precondition(SidebarSizing.width(100) == 280 && SidebarSizing.width(900) == 560)
    precondition(SidebarSizing.width(420,available:320) == 320)
    precondition(SidebarSizing.fontScale(width:420,size:.large) > SidebarSizing.fontScale(width:300,size:.small))
    precondition(SidebarSizing.moved(start:0.5,translation:100,travel:500) == 0.7)
    precondition(SidebarSizing.moved(start:0.5,translation:-1000,travel:500) == 0)
    precondition(SidebarSizing.moved(start:0.5,translation:1000,travel:500) == 1)
    precondition(SidebarSizing.moved(start:0.5,translation:100,travel:0) == 0.5)
    precondition(L10n.usesChinese(["zh-Hans-CN","en-US"]))
    precondition(L10n.usesChinese(["zh-Hant-TW"]))
    precondition(L10n.usesChinese(["zh_Hans"]))
    precondition(!L10n.usesChinese(["en-US","zh-Hans"]))
    precondition(!L10n.usesChinese(["fr-FR","zh-Hans"]))
    precondition(!L10n.usesChinese([]))
    for value in L10n.english.values {
        precondition(!value.isEmpty && !value.unicodeScalars.contains { (0x3400...0x4DBF).contains($0.value) || (0x4E00...0x9FFF).contains($0.value) })
    }
    let previous = L10n.overrideLanguage
    L10n.overrideLanguage = "en"
    precondition(L10n.text("进行中") == "In progress" && L10n.text("开机启动") == "Launch at login")
    precondition(L10n.summary(running:2,unread:1) == "2 running · 1 unread")
    L10n.overrideLanguage = "zh-Hans"
    precondition(L10n.text("进行中") == "进行中")
    L10n.overrideLanguage = previous
    print("PASS: task, sizing, movement, language selection and translation checks")
}
