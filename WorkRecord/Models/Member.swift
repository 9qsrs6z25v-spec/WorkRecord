import Foundation

struct Member: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var title: String        // 職稱: 工程師, 資深工程師, 副理, 經理
    var sys: String          // 系統: Chemical, Special Gas, etc.
    var skill: String        // 技能: Slurry, Gas, etc.
    var grade: String?       // 職等: "31", "32", "33", "33M", "34", "35", "36"
    var plant: String?       // 廠區: AP6A, AP6B
    var dutyPass: Bool       // 已通過值班考核

    init(id: Int, name: String, title: String = "工程師", sys: String = "", skill: String = "", grade: String? = nil, plant: String? = nil, dutyPass: Bool = false) {
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

// 職等 → 職稱對照表
let gradeOptions = ["31", "32", "33", "33M", "34", "35", "36"]

func titleForGrade(_ grade: String) -> String {
    switch grade {
    case "31": return "工程師"
    case "32": return "資深工程師"
    case "33": return "主任工程師"
    case "33M": return "副理"
    case "34": return "副理"
    case "35": return "經理"
    case "36": return "部經理"
    default: return "工程師"
    }
}

let titleOptions = ["工程師", "資深工程師", "主任工程師", "副理", "經理", "部經理"]
let plantOptions = ["", "AP6A", "AP6B"]
