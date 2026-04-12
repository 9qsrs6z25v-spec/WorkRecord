import Foundation

struct Leave: Identifiable, Codable, Equatable {
    var id: Int
    var name: String         // 員工姓名
    var type: String         // 假別: 公假, 病假, 事假, 特休, 補休, 訓練
    var from: String         // 起始日 yyyy-MM-dd
    var to: String           // 結束日 yyyy-MM-dd
    var days: Double         // 天數
    var reason: String       // 事由

    init(id: Int, name: String, type: String = "公假", from: String = "", to: String = "", days: Double = 1, reason: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.from = from
        self.to = to
        self.days = days
        self.reason = reason
    }
}

let leaveTypeOptions = ["公假", "病假", "事假", "特休", "補休", "訓練"]
