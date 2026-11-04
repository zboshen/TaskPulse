import AppKit
import SwiftUI

private let mint = Color(red:0.59,green:0.94,blue:0.78)
struct SidebarView: View {
    @ObservedObject var store: TaskStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var moveStart: CGFloat?
    @State private var moveMouseStart: CGFloat?
    @State private var moveTravel: CGFloat = 0
    @State private var resizeStart: CGFloat?
    @State private var resizeMouseStart: CGFloat?
    var scale: CGFloat { store.fontScale }
    func pt(_ base:CGFloat) -> CGFloat { base * scale }
    @State private var hoverID: String?
    @State private var collapseWork: DispatchWorkItem?
    var body: some View {
        let expanded = store.expanded
        VStack(spacing:0) {
            if expanded { ViewThatFits(in:.vertical) {
                fullContent.fixedSize(horizontal:false,vertical:true)
                ScrollView { fullContent }.scrollIndicators(.hidden)
            }.frame(maxHeight:store.availableHeight - 44).transition(.opacity.combined(with:.offset(x:store.edge == "right" ? 14 : -14))) }
            else { compactContent.transition(.opacity) }
        }
        .padding(.vertical,22)
        .padding(.horizontal,expanded ? pt(25) : 12)
        .frame(width:expanded ? store.panelWidth : 64)
        .background {
            SideNotchShape(edge:store.edge == "right" ? .right : .left)
                .fill(Color(red:0.035,green:0.04,blue:0.045))
                .overlay { SideNotchShape(edge:store.edge == "right" ? .right : .left).stroke(.white.opacity(0.10),lineWidth:0.7) }
        }
        .overlay(alignment:store.edge == "right" ? .leading : .trailing) {
            if expanded { resizeHandle }
        }
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .foregroundStyle(.white)
        .animation(reduceMotion ? nil : NotchMotion.unfold,value:store.expanded)
        .animation(reduceMotion ? nil : NotchMotion.contents,value:store.visible)
        .onHover { inside in
            collapseWork?.cancel()
            if inside { store.expanded = true }
            else if !store.pinned && resizeStart == nil && moveStart == nil {
                let work = DispatchWorkItem { store.expanded = false }; collapseWork = work
                DispatchQueue.main.asyncAfter(deadline:.now()+0.65,execute:work)
            }
        }
    }
    var moveGesture: some Gesture {
        DragGesture(minimumDistance:3,coordinateSpace:.global)
            .onChanged { value in
                let mouseY = NSEvent.mouseLocation.y
                if moveStart == nil {
                    moveStart = store.verticalPosition
                    // SwiftUI Y grows down, screen Y grows up.
                    moveMouseStart = mouseY + value.translation.height
                    moveTravel = store.verticalTravel
                    collapseWork?.cancel()
                }
                store.move(start:moveStart ?? store.verticalPosition,
                           translation:mouseY - (moveMouseStart ?? mouseY),travel:moveTravel)
            }
            .onEnded { _ in moveStart = nil; moveMouseStart = nil; store.savePosition() }
    }
    var resizeHandle: some View {
        ZStack {
            Color.white.opacity(0.001)
            Capsule().fill(.white.opacity(resizeStart == nil ? 0.20 : 0.60))
                .frame(width:3,height:30)
        }
        .frame(width:12)
        .padding(.vertical,28)
        .contentShape(Rectangle())
        .help(L10n.text("左右拖动调整大小"))
        .accessibilityLabel(L10n.text("拖动调整组件大小"))
        .onHover { inside in
            if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
        }
        .gesture(DragGesture(minimumDistance:1,coordinateSpace:.global)
            .onChanged { value in
                let mouseX = NSEvent.mouseLocation.x
                if resizeStart == nil {
                    resizeStart = store.panelWidth
                    resizeMouseStart = mouseX - value.translation.width
                    collapseWork?.cancel()
                }
                // Screen coordinates stay stable while the right-anchored window moves.
                store.resize(start:resizeStart ?? store.panelWidth,translation:mouseX - (resizeMouseStart ?? mouseX))
            }
            .onEnded { _ in resizeStart = nil; resizeMouseStart = nil; store.saveSize() })
    }
    var compactContent: some View {
        VStack(spacing:16) {
            Image(systemName:"sparkle").font(.system(size:20,weight:.medium)).foregroundStyle(mint)
            ForEach(store.visible) { task in
                Group {
                    if task.running { PulseSpinner() }
                    else { Circle().fill(mint).frame(width:7,height:7) }
                }.frame(height:19)
            }
            if store.visible.isEmpty { Circle().fill(.white.opacity(0.25)).frame(width:5,height:5) }
        }.contentShape(Rectangle()).onTapGesture { store.expanded = true }
    }
    var fullContent: some View {
        VStack(alignment:.leading,spacing:pt(19)) {
            HStack(spacing:pt(9)) {
                HStack(spacing:pt(9)) {
                    Image(systemName:"sparkle").foregroundStyle(mint).font(.system(size:pt(19)))
                    Text(L10n.text("任务脉搏")).font(.system(size:pt(16),weight:.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength:0)
                }
                .frame(maxWidth:.infinity,minHeight:pt(26))
                .contentShape(Rectangle())
                .help(L10n.text("按住标题上下拖动，移动卡片位置"))
                .accessibilityElement(children:.combine)
                .accessibilityLabel(L10n.text("任务脉搏，拖动移动位置"))
                .onHover { inside in
                    if inside { NSCursor.openHand.push() } else { NSCursor.pop() }
                }
                .gesture(moveGesture)
                Button { store.newTask() } label: {
                    Image(systemName:"plus.message")
                        .font(.system(size:pt(15),weight:.medium))
                        .foregroundStyle(mint)
                        .frame(width:pt(26),height:pt(26))
                        .contentShape(Rectangle())
                }
                .help(L10n.text("新建任务 · 打开 Codex 新聊天"))
                .accessibilityLabel(L10n.text("新建任务"))
                Button { store.pinned.toggle(); if !store.pinned { store.expanded = false } } label: {
                    Image(systemName:store.pinned ? "pin.fill" : "pin").foregroundStyle(store.pinned ? mint : .secondary)
                }.help(store.pinned ? L10n.text("自动收起") : L10n.text("固定展开"))
                    .accessibilityLabel(store.pinned ? L10n.text("自动收起") : L10n.text("固定展开"))
                if store.snapshotMode {
                    Image(systemName:"slider.horizontal.3").foregroundStyle(.secondary)
                } else {
                    Menu { settings } label: { Image(systemName:"slider.horizontal.3").foregroundStyle(.secondary).accessibilityLabel(L10n.text("显示器与吸附设置")) }
                        .menuStyle(.borderlessButton).fixedSize().help(L10n.text("显示器与吸附设置"))
                }
            }.buttonStyle(.plain)
            HStack(spacing:pt(6)) {
                Circle().fill(store.error == nil ? mint : .orange).frame(width:5,height:5)
                Text(store.demo ? L10n.text("演示预览") : "CODEX · GPT").tracking(1.5)
                Spacer()
                Text(store.error == nil ? L10n.summary(running:store.runningCount,unread:store.unreadCount) : L10n.text("状态待同步")).fixedSize()
            }.font(.system(size:pt(10),weight:.medium)).foregroundStyle(.secondary)
            if let error = store.error, !store.demo {
                Label(L10n.text("连接暂不可用"),systemImage:"exclamationmark.triangle").foregroundStyle(.orange)
                Text(error).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
                HStack {
                    Button(L10n.text("重新读取")) { store.refresh() }
                    Button(L10n.text("复制连接诊断")) { store.copyConnectionDiagnostics() }
                }
            } else if store.visible.isEmpty {
                VStack(spacing:pt(10)) {
                    Image(systemName:"checkmark.circle").font(.system(size:pt(28),weight:.ultraLight)).foregroundStyle(mint.opacity(0.65))
                    Text(L10n.text("一切就绪")).font(.system(size:pt(14),weight:.medium))
                    Text(L10n.text("今天执行中的会话和未读结果\n会自动出现在这里"))
                        .font(.system(size:pt(11))).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }.frame(maxWidth:.infinity).padding(.vertical,22)
            } else {
                let running = store.visible.filter(\.running)
                let done = store.visible.filter { !$0.running }
                if !running.isEmpty { sectionHeader(L10n.text("进行中"),count:store.runningCount,color:mint); rows(running) }
                if !done.isEmpty { sectionHeader(L10n.text("已完成"),count:store.unreadCount,color:Color.white.opacity(0.45)); rows(done) }
                let hidden = store.runningCount + store.unreadCount - store.visible.count
                if hidden > 0 { Text(L10n.more(hidden)).font(.system(size:pt(10))).foregroundStyle(.tertiary) }
            }
            if let message = store.settingsMessage {
                Text(message).font(.system(size:pt(10))).foregroundStyle(.orange)
                    .fixedSize(horizontal:false,vertical:true)
            }
            Rectangle().fill(.white.opacity(0.08)).frame(height:1)
            HStack {
                Text(store.demo ? L10n.text("演示数据") : L10n.text(store.error == nil ? "本机同步 · 每 2 秒" : "自动重连 · 每 2 秒"))
                Spacer()
                Text(L10n.text("最多 5 条"))
            }.font(.system(size:pt(10))).foregroundStyle(.tertiary)
        }
    }
    func sectionHeader(_ title:String,count:Int,color:Color) -> some View {
        HStack(spacing:pt(7)) {
            Text(title).font(.system(size:pt(11),weight:.semibold)).foregroundStyle(color)
            Text(String(count)).font(.system(size:pt(10),design:.monospaced)).foregroundStyle(.secondary)
            Spacer()
            if title == L10n.text("已完成") { Text(L10n.text("最新完成优先 · 仅未读")).font(.system(size:pt(9))).foregroundStyle(.tertiary) }
        }
    }
    func rows(_ tasks:[TaskEntry]) -> some View {
        VStack(spacing:pt(5)) {
            ForEach(tasks) { task in
                HStack(alignment:.top,spacing:pt(11)) {
                    Group {
                        if task.running { PulseSpinner() }
                        else { Image(systemName:"checkmark.circle.fill").foregroundStyle(mint).font(.system(size:pt(16))) }
                    }.frame(width:pt(18),height:pt(20)).padding(.top,2)
                    Button { if !store.demo { store.open(task) } } label: {
                        VStack(alignment:.leading,spacing:pt(6)) {
                            Text(task.title).font(.system(size:pt(12),weight:.medium)).foregroundStyle(.white.opacity(0.93)).lineLimit(2).multilineTextAlignment(.leading)
                            HStack(spacing:pt(5)) {
                                Text(task.detail).lineLimit(1)
                                Spacer(minLength:0)
                                if task.running {
                                    TimelineView(.periodic(from:.now,by:30)) { ctx in
                                        Text(elapsed(task.startedAt,ctx.date)).monospacedDigit()
                                    }
                                } else { Text(completionDate(task.completedAt)).monospacedDigit().fixedSize() }
                            }.font(.system(size:pt(10))).foregroundStyle(.secondary)
                        }.frame(maxWidth:.infinity,alignment:.leading).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    if !task.running {
                        Button { store.dismiss(task) } label: { Image(systemName:"xmark").font(.system(size:pt(9))).foregroundStyle(.secondary) }
                            .buttonStyle(.plain).help(L10n.text("从组件收起这条结果"))
                    }
                }
                .padding(pt(10))
                .background(RoundedRectangle(cornerRadius:10).fill(.white.opacity(hoverID == task.id ? 0.08 : 0.025)))
                .onHover { hoverID = $0 ? task.id : nil }
                .transition(.opacity.combined(with:.move(edge:.trailing)))
            }
        }.padding(.horizontal,-pt(10))
    }
    func completionDate(_ time:Double) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier:"Asia/Shanghai")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from:Date(timeIntervalSince1970:time))
    }
    func elapsed(_ time:Double,_ now:Date) -> String {
        let m = max(0,Int(now.timeIntervalSince1970-time)/60)
        return L10n.elapsed(minutes:m)
    }
    @ViewBuilder var settings: some View {
        Toggle(L10n.text("开机启动"),isOn:Binding(get:{ store.launchAtLogin },set:{ store.setLaunchAtLogin($0) }))
        if store.loginNeedsApproval { Button(L10n.text("前往系统登录项设置")) { store.openLoginSettings() } }
        Toggle(L10n.text("在 Dock 中隐藏"),isOn:Binding(get:{ store.dockHidden },set:{ store.setDockHidden($0) }))
        Divider()
        Button(L10n.text("复制连接诊断")) { store.copyConnectionDiagnostics() }
        Divider()
        Button(L10n.text("恢复垂直居中")) { store.centerPosition() }
        Divider()
        Menu(L10n.text("内容大小")) {
            ForEach(ContentSize.allCases) { size in
                Button((store.contentSize == size ? "✓ " : "") + size.title) { store.chooseSize(size) }
            }
        }
        Divider()
        Text(L10n.text("吸附显示器"))
        Button((store.display == "primary" ? "✓ " : "") + L10n.text("主显示器")) { store.configure(display:"primary") }
        ForEach(Array(NSScreen.screens.enumerated()),id:\.offset) { index,screen in
            let id = displayID(screen)
            if index > 0 { Button((store.display == id ? "✓ " : "") + L10n.text("副显示器 · ") + screen.localizedName) { store.configure(display:id) } }
        }
        Divider()
        Button((store.edge == "left" ? "✓ " : "") + L10n.text("左侧吸附")) { store.configure(edge:"left") }
        Button((store.edge == "right" ? "✓ " : "") + L10n.text("右侧吸附")) { store.configure(edge:"right") }
        Divider()
        Button(store.demo ? L10n.text("退出演示") : L10n.text("预览外观（演示数据）")) { store.toggleDemo() }
        Button(L10n.text("退出任务脉搏")) { NSApp.terminate(nil) }
    }
}
func displayID(_ screen:NSScreen) -> String {
    String((screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0)
}

private struct PulseSpinner: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var spinning = false
    var body: some View {
        Circle().stroke(mint.opacity(0.15),lineWidth:1.8)
            .overlay { Circle().trim(from:0.05,to:0.72).stroke(mint,style:StrokeStyle(lineWidth:1.8,lineCap:.round))
                .rotationEffect(.degrees(spinning ? 360 : 0)) }
            .frame(width:14,height:14)
            .onAppear { if !reduceMotion { withAnimation(.linear(duration:1).repeatForever(autoreverses:false)) { spinning = true } } }
            .accessibilityLabel(L10n.text("正在执行"))
    }
}
