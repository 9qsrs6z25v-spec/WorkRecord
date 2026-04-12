import Foundation

struct Duty: Identifiable, Codable, Equatable {
    var id: Int
    var date: String         // yyyy-MM-dd
    var fab: String          // A or B
    var person: String       // 值班人員
    var type: String         // 平日值班, 例假值班, 夜班, 小夜班, 夜班休假...
    var shift: String        // 班次時段 e.g. "08:30–20:30"
    var backup: String       // 備援人員
    var note: String         // 備註
    var nightGroup: String?  // 夜班同組標記
    var eveGroup: String?    // 小夜班同組標記

    init(id: Int, date: String = "", fab: String = "A", person: String = "",
         type: String = "平日值班", shift: String = "08:30–20:30",
         backup: String = "", note: String = "",
         nightGroup: String? = nil, eveGroup: String? = nil) {
        self.id = id
        self.date = date
        self.fab = fab
        self.person = person
        self.type = type
        self.shift = shift
        self.backup = backup
        self.note = note
        self.nightGroup = nightGroup
        self.eveGroup = eveGroup
    }
}

let dutyTypeOptions = ["平日值班", "例假值班", "國定假日值班", "颱風值班", "緊急支援"]

enum DutyMode: String, CaseIterable {
    case day = "日班"
    case night = "夜班"
    case eve = "小夜班"

    var icon: String {
        switch self {
        case .day: return "☀️"
        case .night: return "🌙"
        case .eve: return "🌆"
        }
    }

    var label: String {
        switch self {
        case .day: return "☀️ 日班"
        case .night: return "🌙 夜班（6天）"
        case .eve: return "🌆 小夜班（5天）"
        }
    }
}
