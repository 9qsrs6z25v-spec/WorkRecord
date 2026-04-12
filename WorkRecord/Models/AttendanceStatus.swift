import SwiftUI

struct AttendanceStatus {
    let code: String       // present, sick, leave, personal, training, duty, holiday, night-rest
    let label: String
    let reason: String
    let days: Double
    let fab: String
    let isNight: Bool
    let isEve: Bool

    init(code: String, label: String, reason: String = "", days: Double = 0,
         fab: String = "", isNight: Bool = false, isEve: Bool = false) {
        self.code = code
        self.label = label
        self.reason = reason
        self.days = days
        self.fab = fab
        self.isNight = isNight
        self.isEve = isEve
    }

    var statusColor: Color {
        switch code {
        case "present": return Color(hex: "3fb950")
        case "sick": return Color(hex: "f85149")
        case "leave", "personal": return Color(hex: "a371f7")
        case "training": return Color(hex: "388bfd")
        case "duty": return fab == "A" ? Color(hex: "388bfd") : Color(hex: "a371f7")
        case "holiday": return Color(hex: "303d3d").opacity(0.5)
        case "night-rest": return Color(hex: "5a3c82")
        default: return Color(hex: "d29922")
        }
    }

    var statusIcon: String {
        switch code {
        case "present": return "✓"
        case "sick": return "✗"
        case "leave", "personal": return "△"
        case "training": return "◎"
        case "duty":
            if isEve { return "🌆" }
            return "🏭"
        case "holiday": return "🌙"
        case "night-rest": return "🌘"
        default: return "△"
        }
    }

    var statusText: String {
        switch code {
        case "present": return "出勤"
        case "sick": return "病假"
        case "leave": return label
        case "personal": return label
        case "training": return label
        case "duty":
            if isEve { return "\(fab)廠小夜班" }
            return "\(fab)廠值班"
        case "holiday": return "休假"
        case "night-rest": return "夜班休假"
        default: return label
        }
    }

    var heatmapColor: Color {
        switch code {
        case "present": return Color(hex: "3fb950").opacity(0.7)
        case "sick": return Color(hex: "f85149").opacity(0.7)
        case "training": return Color(hex: "388bfd").opacity(0.7)
        case "personal", "leave": return Color(hex: "a371f7").opacity(0.7)
        case "holiday": return Color(hex: "30363d").opacity(0.35)
        case "night-rest": return Color(hex: "5a3c82").opacity(0.4)
        case "duty":
            if isEve { return Color(hex: "d29922").opacity(0.85) }
            if isNight { return Color(hex: "3c1478").opacity(0.75) }
            return Color(hex: "ea8a28").opacity(0.85)
        default: return Color(hex: "d29922").opacity(0.8)
        }
    }
}
