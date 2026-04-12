import Foundation

struct Member: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var title: String        // 職稱: 工程師, 資深工程師, 副理, 經理
    var sys: String          // 系統: Chemical, Special Gas, etc.
    var skill: String        // 技能: Slurry, Gas, etc.
    var grade: Int?          // 職等: 31, 32...
    var plant: String?       // 廠區: AP6A, AP6B
    var dutyPass: Bool       // 已通過值班考核

    init(id: Int, name: String, title: String = "工程師", sys: String = "", skill: String = "", grade: Int? = nil, plant: String? = nil, dutyPass: Bool = false) {
        self.id = id
        self.name = name
        self.title = title
        self.sys = sys
        self.skill = skill
        self.grade = grade
        self.plant = plant
        self.dutyPass = dutyPass
    }
}

let titleOptions = ["工程師", "資深工程師", "副理", "經理"]
let plantOptions = ["", "AP6A", "AP6B"]
