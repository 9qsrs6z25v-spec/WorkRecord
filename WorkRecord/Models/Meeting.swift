import Foundation

struct Meeting: Identifiable, Codable, Equatable {
    var id: Int
    var date: String         // yyyy-MM-dd
    var name: String         // 會議名稱
    var time: String         // e.g. "09:00–10:00"
    var place: String        // 地點
    var note: String         // 說明

    init(id: Int, date: String = "", name: String = "", time: String = "", place: String = "AP6A", note: String = "") {
        self.id = id
        self.date = date
        self.name = name
        self.time = time
        self.place = place
        self.note = note
    }
}

let meetingPlaceOptions = ["AP6A", "AP6B", "遠端", "其他"]
let meetingDurationOptions: [(String, Int)] = [
    ("30 分鐘", 30),
    ("1 小時", 60),
    ("1.5 小時", 90),
    ("2 小時", 120),
    ("3 小時", 180),
    ("4 小時", 240)
]
