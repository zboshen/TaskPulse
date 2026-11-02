import AppKit
import SwiftUI

@MainActor final class TaskStore: ObservableObject {
    @Published var dockHidden = UserDefaults.standard.object(forKey:"dockHidden") as? Bool ?? true
    @Published var launchAtLogin = false
    @Published var loginNeedsApproval = false
    @Published var settingsMessage: String?
    var snapshotMode = false
    @Published var tasks: [TaskEntry] = []
    @Published var error: String?
    @Published var expanded = true
    @Published var pinned = true
    @Published var demo = false
    @Published var lastRefresh: Date?
    @Published var edge: String = UserDefaults.standard.string(forKey:"edge") ?? "right"
    @Published var display: String = UserDefaults.standard.string(forKey:"display") ?? "primary"
    @Published var panelWidth: CGFloat = SidebarSizing.width(UserDefaults.standard.object(forKey:"panelWidth") as? Double ?? 346)
    @Published var contentSize: ContentSize = ContentSize(rawValue:UserDefaults.standard.string(forKey:"contentSize") ?? "medium") ?? .medium
    @Published var availableWidth: CGFloat = 560
    @Published var availableHeight: CGFloat = 900
    @Published var verticalPosition: CGFloat = SidebarSizing.position(UserDefaults.standard.object(forKey:"verticalPosition") as? Double ?? 0.5)
    var verticalTravel: CGFloat = 0
    func move(start:CGFloat, translation:CGFloat, travel:CGFloat) {
        let position = SidebarSizing.moved(start:start,translation:translation,travel:travel)
        if verticalPosition != position { verticalPosition = position }
    }
    func savePosition() { UserDefaults.standard.set(Double(verticalPosition),forKey:"verticalPosition") }
    func centerPosition() { verticalPosition = 0.5; savePosition() }
    var fontScale: CGFloat { SidebarSizing.fontScale(width:panelWidth,size:contentSize) }
    func resize(start:CGFloat, translation:CGFloat) {
        let width = SidebarSizing.resized(start:start,translation:translation,rightEdge:edge == "right",available:availableWidth)
        if panelWidth != width { panelWidth = width }
    }
    func saveSize() { UserDefaults.standard.set(Double(panelWidth),forKey:"panelWidth") }
    func chooseSize(_ size:ContentSize) {
        contentSize = size
        panelWidth = SidebarSizing.width(size.width,available:availableWidth)
        UserDefaults.standard.set(size.rawValue,forKey:"contentSize")
        saveSize()
    }
    private var dismissed = Set(UserDefaults.standard.stringArray(forKey:"dismissed") ?? [])
    private var timer: Timer?
    private var languageObserver: NSObjectProtocol?
    private var loading = false
    var visible: [TaskEntry] { TaskPolicy.visible(tasks,dismissed:dismissed) }
    var runningCount: Int { tasks.filter(\.running).count }
    var unreadCount: Int { tasks.filter { $0.status == "completed" && $0.unread && !dismissed.contains($0.receiptKey) }.count }
    var reposition: (() -> Void)?
    func start() {
        languageObserver = NotificationCenter.default.addObserver(forName:NSLocale.currentLocaleDidChangeNotification,object:nil,queue:.main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.objectWillChange.send()
                if self.demo { self.demo = false; self.toggleDemo() } else { self.refresh() }
            }
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval:2,repeats:true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
    func refresh() {
        guard !loading, !demo else { return }; loading = true
        DispatchQueue.global(qos:.utility).async {
            let result = Result { try LocalTaskReader().read() }
            DispatchQueue.main.async {
                self.loading = false
                guard !self.demo else { return }
                switch result {
                case .success(let tasks): self.tasks = tasks; self.error = nil; self.lastRefresh = Date()
                case .failure(let error): self.error = error.localizedDescription; self.tasks = []
                }
            }
        }
    }
    func newTask() {
        // The desktop app routes codex://new?mode=codex to a blank new-thread composer.
        guard let url = URL(string:"codex://new?mode=codex") else { return }
        if !NSWorkspace.shared.open(url) {
            error = L10n.text("无法打开 Codex 新聊天，请确认应用已安装")
        }
    }
    func open(_ task: TaskEntry) {
        guard let url = URL(string:task.url), ["codex","chatgpt","https"].contains(url.scheme ?? "") else { return }
        // Opening the conversation lets Codex record the actual read receipt.
        NSWorkspace.shared.open(url)
    }
    func dismiss(_ task: TaskEntry) {
        dismissed.insert(task.receiptKey)
        UserDefaults.standard.set(Array(dismissed.suffix(1000)),forKey:"dismissed")
        objectWillChange.send()
    }
    func configure(edge: String? = nil, display: String? = nil) {
        if let edge { self.edge = edge; UserDefaults.standard.set(edge,forKey:"edge") }
        if let display { self.display = display; UserDefaults.standard.set(display,forKey:"display") }
        reposition?()
    }
    func toggleDemo() {
        demo.toggle()
        if demo {
            let now = Date().timeIntervalSince1970
            tasks = [
                TaskEntry(id:"demo-1",turnID:"1",title:L10n.text("构建你的桌面任务组件"),status:"inProgress",startedAt:now-130,unread:false,detail:L10n.text("正在编译与验证"),url:""),
                TaskEntry(id:"demo-2",turnID:"1",title:L10n.text("为产品页面生成交互原型"),status:"inProgress",startedAt:now-630,unread:false,detail:L10n.text("正在完善界面细节"),url:""),
                TaskEntry(id:"demo-3",turnID:"1",title:L10n.text("整理本周开发进展"),status:"completed",startedAt:now-1500,completedAt:now-80,unread:true,detail:L10n.text("报告已准备好 · 未读"),url:"")]
        } else { tasks = []; refresh() }
    }
}
