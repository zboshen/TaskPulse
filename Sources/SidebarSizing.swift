import Foundation

enum ContentSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
    var title: String { switch self { case .small: return L10n.text("小"); case .medium: return L10n.text("中"); case .large: return L10n.text("大") } }
    var scale: CGFloat { switch self { case .small: return 0.88; case .medium: return 1; case .large: return 1.18 } }
    var width: CGFloat { switch self { case .small: return 300; case .medium: return 346; case .large: return 420 } }
}
enum SidebarSizing {
    static let collapsedWidth: CGFloat = 20
    static let collapsedHeight: CGFloat = 80
    static let collapsedPillWidth: CGFloat = 12
    static let collapsedPillHeight: CGFloat = 64
    static let collapsedCoreWidth: CGFloat = 3
    static let collapsedCoreHeight: CGFloat = 28

    static func position(_ proposed:CGFloat) -> CGFloat {
        min(1,max(0,proposed.isFinite ? proposed : 0.5))
    }
    static func moved(start:CGFloat,translation:CGFloat,travel:CGFloat) -> CGFloat {
        guard travel > 0 else { return position(start) }
        return position(start + translation/travel)
    }
    static let minimumWidth: CGFloat = 280
    static let maximumWidth: CGFloat = 560
    static func width(_ proposed: CGFloat, available: CGFloat = 560) -> CGFloat {
        min(max(proposed.isFinite ? proposed : 346, min(minimumWidth,available)), min(maximumWidth,available))
    }
    static func resized(start:CGFloat, translation:CGFloat, rightEdge:Bool, available:CGFloat) -> CGFloat {
        width(start + (rightEdge ? -translation : translation), available:available)
    }
    static func fontScale(width:CGFloat, size:ContentSize) -> CGFloat {
        size.scale * min(1.10,max(0.94,width / size.width))
    }
}
