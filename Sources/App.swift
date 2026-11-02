import AppKit
import SwiftUI
import Combine

final class TaskPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = TaskStore()
    var panel: TaskPanel!
    var host: NSHostingView<SidebarView>!
    var status: NSStatusItem!
    var change: AnyCancellable?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(store.dockHidden ? .accessory : .regular)
        store.refreshLoginState()
        if CommandLine.arguments.contains("--demo") { store.toggleDemo() }
        panel = TaskPanel(contentRect:NSRect(x:0,y:0,width:346,height:200),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary,.stationary]
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        host = NSHostingView(rootView:SidebarView(store:store)); panel.contentView = host
        store.reposition = { [weak self] in self?.layout() }
        change = store.objectWillChange.sink { [weak self] in DispatchQueue.main.async { self?.layout() } }
        NotificationCenter.default.addObserver(self,selector:#selector(screensChanged),name:NSApplication.didChangeScreenParametersNotification,object:nil)
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        status.button?.image = NSImage(systemSymbolName:"sidebar.right",accessibilityDescription:"任务脉搏")
        status.button?.target = self; status.button?.action = #selector(toggle)
        layout(); panel.orderFrontRegardless(); store.start()
    }
    @objc func screensChanged() { layout() }
    @objc func toggle() { store.expanded.toggle(); store.pinned = store.expanded; panel.orderFrontRegardless() }
    func layout() {
        guard let primary = NSScreen.screens.first else { return }
        let screen = store.display == "primary" ? primary : NSScreen.screens.first { displayID($0) == store.display } ?? primary
        let availableWidth = max(64,screen.visibleFrame.width-24)
        let availableHeight = max(120,screen.visibleFrame.height-24)
        if store.availableWidth != availableWidth { store.availableWidth = availableWidth }
        if store.availableHeight != availableHeight { store.availableHeight = availableHeight }
        let width:CGFloat = store.expanded ? SidebarSizing.width(store.panelWidth,available:availableWidth) : 64
        if store.expanded && store.panelWidth != width { store.panelWidth = width }
        let height = min(host.fittingSize.height,screen.visibleFrame.height-24)
        let x = store.edge == "right" ? screen.frame.maxX-width : screen.frame.minX
        let travel = max(0,screen.visibleFrame.height-height-24)
        store.verticalTravel = travel
        let y = screen.visibleFrame.minY + 12 + travel * store.verticalPosition
        let frame = NSRect(x:x,y:y,width:width,height:height)
        panel.setFrame(frame,display:true)
    }
}

@main struct TaskPulse {
    @MainActor static func main() {
        if CommandLine.arguments.contains("--self-test") { runPolicyTests(); return }
        if CommandLine.arguments.contains("--dump") {
            do {
                let tasks = try LocalTaskReader().read()
                let data = try JSONEncoder().encode(TaskPolicy.visible(tasks))
                print(String(decoding:data,as:UTF8.self))
            } catch { fputs("\(error)\n",stderr); exit(1) }
            return
        }
        if CommandLine.arguments.contains("--preview") {
            let store = TaskStore(); store.snapshotMode = true; store.toggleDemo()
            if let index = CommandLine.arguments.firstIndex(of:"--size"),CommandLine.arguments.count > index+1,
               let size = ContentSize(rawValue:CommandLine.arguments[index+1]) {
                store.contentSize = size; store.panelWidth = size.width
            }
            let view = SidebarView(store:store)
            let renderer = ImageRenderer(content:view)
            renderer.scale = 2
            if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data:tiff),let data = bitmap.representation(using:.png,properties:[:]) {
                try? data.write(to:URL(fileURLWithPath:CommandLine.arguments.last!))
            }
            return
        }
        let app = NSApplication.shared
        let delegate = AppDelegate(); app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
