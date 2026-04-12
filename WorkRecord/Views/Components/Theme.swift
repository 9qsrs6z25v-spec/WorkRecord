import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - App Theme
struct AppTheme {
    static let ink = Color(hex: "16213e")
    static let ink2 = Color(hex: "0f3460")
    static let gold = Color(hex: "e2b04a")
    static let gold2 = Color(hex: "f5d78e")
    static let cream = Color(hex: "faf6ee")
    static let paper = Color(hex: "f4efe5")
    static let rust = Color(hex: "c0533a")
    static let sage = Color(hex: "3d7a5a")
    static let muted = Color(hex: "9a9080")
    static let border = Color(hex: "ddd5c0")
    static let blue = Color(hex: "2e6fb5")
    static let purple = Color(hex: "7b52a8")
    static let card = Color.white
    static let bg = Color(hex: "ede8de")

    static let present = Color(hex: "3fb950")
    static let sick = Color(hex: "f85149")
    static let leave = Color(hex: "d29922")
    static let training = Color(hex: "388bfd")
    static let personal = Color(hex: "a371f7")
}

// MARK: - Badge Style
struct BadgeStyle {
    let bg: Color
    let fg: Color
    let border: Color

    static func forLeaveType(_ type: String) -> BadgeStyle {
        switch type {
        case "公假", "訓練":
            return BadgeStyle(bg: Color(hex: "eef4fb"), fg: AppTheme.blue, border: Color(hex: "b5cff0"))
        case "病假":
            return BadgeStyle(bg: Color(hex: "fdf0ec"), fg: AppTheme.rust, border: Color(hex: "f0c5b5"))
        case "事假":
            return BadgeStyle(bg: Color(hex: "fdf8ec"), fg: Color(hex: "9a7020"), border: Color(hex: "e0c878"))
        case "特休", "補休":
            return BadgeStyle(bg: Color(hex: "e8f5ee"), fg: AppTheme.sage, border: Color(hex: "b5ddc5"))
        default:
            return BadgeStyle(bg: Color(hex: "f5f0e8"), fg: AppTheme.muted, border: AppTheme.border)
        }
    }
}
