import Foundation

enum L10n {
    // Preview/test override only. Normal launches follow macOS preferred languages.
    static var overrideLanguage: String?
    static func usesChinese(_ preferred:[String]) -> Bool {
        guard let first = preferred.first?.replacingOccurrences(of:"_",with:"-").lowercased() else { return false }
        return first == "zh" || first.hasPrefix("zh-")
    }
    static var isChinese: Bool { usesChinese(overrideLanguage.map { [$0] } ?? Locale.preferredLanguages) }
    static func text(_ key:String) -> String { isChinese ? key : (english[key] ?? key) }
    static func summary(running:Int,unread:Int) -> String {
        isChinese ? "\(running) 执行 · \(unread) 未读" : "\(running) running · \(unread) unread"
    }
    static func more(_ count:Int) -> String {
        isChinese ? "另有 \(count) 条 · 优先展示最新进行中" : "\(count) more · Newest running tasks first"
    }
    static func elapsed(minutes:Int) -> String {
        if minutes < 1 { return isChinese ? "刚刚" : "Just now" }
        if minutes < 60 { return isChinese ? "\(minutes)分" : "\(minutes)m" }
        return isChinese ? "\(minutes/60)时\(minutes%60)分" : "\(minutes/60)h \(minutes%60)m"
    }
    static let english: [String:String] = [
        "打开会话数据库失败": "Could not open the conversation database",
        "打开任务历史数据库失败": "Could not open the task history database",
        "初始化只读连接失败": "Could not initialize the read-only connection",
        "开始读取任务失败": "Could not start reading tasks",
        "结束读取任务失败": "Could not finish reading tasks",
        "读取任务结构失败": "Could not read the task schema",
        "读取任务数据失败": "Could not read task data",
        "复制连接诊断": "Copy connection diagnostics",
        "连接诊断已复制": "Connection diagnostics copied",
        "状态待同步": "Awaiting sync",
        "自动重连 · 每 2 秒": "Auto-retry · Every 2s",
        "任务脉搏": "TaskPulse",
        "左右拖动调整大小": "Drag sideways to resize",
        "拖动调整组件大小": "Resize widget",
        "按住标题上下拖动，移动卡片位置": "Drag the title up or down to move the widget",
        "任务脉搏，拖动移动位置": "TaskPulse, drag to move",
        "新建任务 · 打开 Codex 新聊天": "New task · Open a new Codex chat",
        "新建任务": "New task",
        "自动收起": "Auto-collapse",
        "固定展开": "Keep expanded",
        "显示器与吸附设置": "Widget settings",
        "演示预览": "DEMO PREVIEW",
        "连接暂不可用": "Connection unavailable",
        "重新读取": "Retry",
        "一切就绪": "All caught up",
        "今天执行中的会话和未读结果\n会自动出现在这里": "Today's running tasks and unread results\nwill appear here automatically",
        "进行中": "In progress",
        "已完成": "Completed",
        "演示数据": "Demo data",
        "本机同步 · 每 2 秒": "Local sync · Every 2s",
        "最多 5 条": "Up to 5 tasks",
        "最新完成优先 · 仅未读": "Latest first · Unread only",
        "从组件收起这条结果": "Dismiss this result from the widget",
        "开机启动": "Launch at login",
        "前往系统登录项设置": "Open Login Items settings",
        "在 Dock 中隐藏": "Hide from Dock",
        "恢复垂直居中": "Center vertically",
        "内容大小": "Content size",
        "吸附显示器": "Display",
        "主显示器": "Primary display",
        "副显示器 · ": "Secondary display · ",
        "左侧吸附": "Dock to left edge",
        "右侧吸附": "Dock to right edge",
        "退出演示": "Exit demo",
        "预览外观（演示数据）": "Preview with demo tasks",
        "退出任务脉搏": "Quit TaskPulse",
        "正在执行": "Working",
        "完成 · 未读": "Done · Unread",
        "Codex 任务": "Codex task",
        "小": "Small",
        "中": "Medium",
        "大": "Large",
        "请先将 TaskPulse 拖入“应用程序”，再启用开机启动。": "Move TaskPulse to Applications before enabling launch at login.",
        "请在系统设置的“登录项”中允许 TaskPulse。": "Allow TaskPulse in System Settings → Login Items.",
        "登录项设置失败：": "Could not update login item: ",
        "暂时无法更改 Dock 显示，请重启组件后重试。": "Could not update Dock visibility. Restart TaskPulse and try again.",
        "无法打开 Codex 新聊天，请确认应用已安装": "Could not open a new Codex chat. Make sure Codex is installed.",
        "构建你的桌面任务组件": "Build the desktop task widget",
        "正在编译与验证": "Building and verifying",
        "为产品页面生成交互原型": "Prototype the product page",
        "正在完善界面细节": "Refining the interface",
        "整理本周开发进展": "Summarize this week’s progress",
        "报告已准备好 · 未读": "Report ready · Unread",
        "无法读取 Codex 数据库，请检查数据目录": "Could not read the Codex database. Check the data directory.",
        "缺少 Codex 任务历史库": "Codex task history database is missing.",
        "Codex 数据结构不兼容：": "Unsupported Codex data schema: ",
        "任务读取中断": "Task data could not be read completely.",
        "无法识别当前应用账户，未读状态暂不可用": "Could not identify the current account. Unread status is unavailable.",
        "当前应用未读状态尚不可用": "Desktop unread state is not available yet.",
    ]
}
