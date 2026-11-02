import SwiftUI
// Support for the unmodified MIT-licensed CodeNotch shape and springs.
enum NotchLayout { static let curlRadius: CGFloat = 14; static let cornerRadius: CGFloat = 24 }
enum NotchEdge: String { case right, left, top, bottom
 var isVertical: Bool { self == .left || self == .right }
}
