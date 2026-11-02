import AppKit
import ServiceManagement

extension TaskStore {
    func refreshLoginState() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        loginNeedsApproval = SMAppService.mainApp.status == .requiresApproval
    }
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                let path = Bundle.main.bundleURL.path
                let userApps = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path + "/"
                guard path.hasPrefix("/Applications/") || path.hasPrefix(userApps) else {
                    settingsMessage = L10n.text("请先将 TaskPulse 拖入“应用程序”，再启用开机启动。")
                    return
                }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLoginState()
            settingsMessage = loginNeedsApproval ? L10n.text("请在系统设置的“登录项”中允许 TaskPulse。") : nil
        } catch {
            refreshLoginState()
            settingsMessage = L10n.text("登录项设置失败：") + error.localizedDescription
        }
    }
    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }
    func setDockHidden(_ hidden:Bool) {
        guard NSApp.setActivationPolicy(hidden ? .accessory : .regular) else {
            settingsMessage = L10n.text("暂时无法更改 Dock 显示，请重启组件后重试。")
            return
        }
        dockHidden = hidden
        UserDefaults.standard.set(hidden,forKey:"dockHidden")
    }
}
