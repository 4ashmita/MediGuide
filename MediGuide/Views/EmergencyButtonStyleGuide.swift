import SwiftUI

enum EmergencyButtonStyleGuide {
    static let diameter: CGFloat = 52
    static let iconSize: CGFloat = 17
    static let labelFontSize: CGFloat = 10
    // Exact red used for the Call 911 tier — never changes per color mode
    static let red = Color(red: 0.94, green: 0.1, blue: 0.1)
    static let shadowRadius: CGFloat = 6
    static let shadowY: CGFloat = 3
    static let shadowOpacity: Double = 0.35
    static let trailingPadding: CGFloat = 16
    static let pressedScale: CGFloat = 0.93
}
