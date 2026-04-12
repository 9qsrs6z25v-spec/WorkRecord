import SwiftUI
import Combine

class DataStore: ObservableObject {
    // MARK: - Published Data
    @Published var members: [Member] = []
    @Published var leaves: [Leave] = []
    @Published var meetings: [Meeting] = []
    @Published var duties: [Duty] = []

    // MARK: - UI State
    @Published var selectedDate: Date = Date()
    @Published var calendarYear: Int = Calendar.current.component(.year, from: Date())
    @Published var calendarMonth: Int = Calendar.current.component(.month, from: Date()) - 1 // 0-based

    // MARK: - Keys
    private let membersKey = "fg2_members"
    private let leavesKey = "fg2_leaves"
    private let meetingsKey = "fg2_meetings"
    private let dutyKey = "fg2_duty"
    private let versionKey = "fg2_app_version"
    private let appVersion = "v3_work_only"

    // MARK: - Init
    init() {
        checkVersion()
        loadAll()
    }

    // MARK: - Version Check
    private func checkVersion() {
        let saved = UserDefaults.standard.string(forKey: versionKey)
        if saved != appVersion {
            let keys = UserDefaults.standard.dictionaryRepresentation().keys.filter {
                $0.hasPrefix("fg2_") || $0.hasPrefix("fg_")
            }
            keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
            UserDefaults.standard.set(appVersion, forKey: versionKey)
        }
    }

    // MARK: - Load
    func loadAll() {
        members = load(key: membersKey) ?? Self.presetMembers
        leaves = load(key: leavesKey) ?? Self.presetLeaves
        meetings = load(key: meetingsKey) ?? Self.presetMeetings
        duties = load(key: dutyKey) ?? []

        // Write defaults if first load
        if load(key: membersKey) as [Member]? == nil { save(key: membersKey, data: members) }
        if load(key: leavesKey) as [Leave]? == nil { save(key: leavesKey, data: leaves) }
        if load(key: meetingsKey) as [Meeting]? == nil { save(key: meetingsKey, data: meetings) }
        if load(key: dutyKey) as [Duty]? == nil { save(key: dutyKey, data: duties) }
    }

    // MARK: - Persistence Helpers
    private func load<T: Codable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Codable>(key: String, data: T) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func saveMembers() { save(key: membersKey, data: members) }
    func saveLeaves() { save(key: leavesKey, data: leaves) }
    func saveMeetings() { save(key: meetingsKey, data: meetings) }
    func saveDuties() { save(key: dutyKey, data: duties) }

    // MARK: - ID Generator
    func newId() -> Int {
        Int(Date().timeIntervalSince1970 * 1000) + Int.random(in: 0..<1000)
    }

    // MARK: - Member CRUD
    func addMember(_ member: Member) {
        members.append(member)
        saveMembers()
    }

    func updateMember(_ member: Member) {
        if let idx = members.firstIndex(where: { $0.id == member.id }) {
            members[idx] = member
            saveMembers()
        }
    }

    func deleteMember(_ id: Int) {
        members.removeAll { $0.id == id }
        saveMembers()
    }

    // MARK: - Leave CRUD
    func addLeave(_ leave: Leave) {
        leaves.append(leave)
        saveLeaves()
    }

    func updateLeave(_ leave: Leave) {
        if let idx = leaves.firstIndex(where: { $0.id == leave.id }) {
            leaves[idx] = leave
            saveLeaves()
        }
    }

    func deleteLeave(_ id: Int) {
        leaves.removeAll { $0.id == id }
        saveLeaves()
    }

    // MARK: - Meeting CRUD
    func addMeeting(_ meeting: Meeting) {
        meetings.append(meeting)
        saveMeetings()
    }

    func updateMeeting(_ meeting: Meeting) {
        if let idx = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[idx] = meeting
            saveMeetings()
        }
    }

    func deleteMeeting(_ id: Int) {
        meetings.removeAll { $0.id == id }
        saveMeetings()
    }

    // MARK: - Duty CRUD
    func addDuty(_ duty: Duty) {
        duties.append(duty)
        saveDuties()
    }

    func addDuties(_ newDuties: [Duty]) {
        duties.append(contentsOf: newDuties)
        saveDuties()
    }

    func updateDuty(_ duty: Duty) {
        if let idx = duties.firstIndex(where: { $0.id == duty.id }) {
            duties[idx] = duty
            saveDuties()
        }
    }

    func deleteDuty(_ id: Int) {
        duties.removeAll { $0.id == id }
        saveDuties()
    }

    func deleteDutyNightGroup(groupDate: String, person: String) {
        duties.removeAll { $0.nightGroup == groupDate && $0.person == person }
        saveDuties()
    }

    func deleteDutyEveGroup(groupDate: String, person: String) {
        duties.removeAll { $0.eveGroup == groupDate && $0.person == person }
        saveDuties()
    }

    // MARK: - Attendance Logic
    func getStatus(name: String, dateStr: String) -> AttendanceStatus {
        let isHol = DateHelper.isWeekend(dateStr)

        // Night rest
        if let nightRest = duties.first(where: { $0.date == dateStr && $0.person == name && $0.type == "夜班休假" }) {
            return AttendanceStatus(code: "night-rest", label: nightRest.shift.isEmpty ? "夜班休假" : nightRest.shift, reason: nightRest.note.isEmpty ? nightRest.shift : nightRest.note)
        }

        // On duty (exclude night rest)
        if let onDuty = duties.first(where: { $0.date == dateStr && $0.person == name && $0.type != "夜班休假" }) {
            let lbl = onDuty.type == "小夜班" ? "小夜班 \(onDuty.fab)廠" : "值班 \(onDuty.fab)廠"
            let rsn = "\(onDuty.fab)廠 \(onDuty.shift)" + (onDuty.backup.isEmpty ? "" : " 備援:\(onDuty.backup)")
            let isNight = onDuty.type == "夜班" || onDuty.shift.contains("夜班")
            let isEve = onDuty.type == "小夜班"
            return AttendanceStatus(code: "duty", label: lbl, reason: rsn, fab: onDuty.fab, isNight: isNight, isEve: isEve)
        }

        if isHol {
            return AttendanceStatus(code: "holiday", label: "例假日")
        }

        // Check leaves
        let matched = leaves.filter { leave in
            guard leave.name == name else { return false }
            guard let f = DateHelper.parseDate(leave.from),
                  let t = DateHelper.parseDate(leave.to),
                  let d = DateHelper.parseDate(dateStr) else { return false }
            return d >= f && d <= t
        }

        if matched.isEmpty {
            return AttendanceStatus(code: "present", label: "正常出勤")
        }

        let l = matched[0]
        switch l.type {
        case "病假":
            return AttendanceStatus(code: "sick", label: "病假", reason: l.reason, days: l.days)
        case "事假":
            return AttendanceStatus(code: "personal", label: "事假", reason: l.reason, days: l.days)
        case "特休":
            return AttendanceStatus(code: "personal", label: "特休", reason: l.reason, days: l.days)
        case "補休":
            return AttendanceStatus(code: "personal", label: "補休", reason: l.reason, days: l.days)
        case "訓練":
            return AttendanceStatus(code: "training", label: "訓練", reason: l.reason, days: l.days)
        case "公假":
            return AttendanceStatus(code: "training", label: "公假", reason: l.reason, days: l.days)
        default:
            return AttendanceStatus(code: "leave", label: l.type, reason: l.reason, days: l.days)
        }
    }

    // MARK: - Export / Import
    struct ExportData: Codable {
        let version: String
        let exportedAt: String
        let members: [Member]
        let leaves: [Leave]
        let meetings: [Meeting]
        let duties: [Duty]
    }

    func exportJSON() -> Data? {
        let export = ExportData(
            version: appVersion,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            members: members,
            leaves: leaves,
            meetings: meetings,
            duties: duties
        )
        return try? JSONEncoder().encode(export)
    }

    func importJSON(_ data: Data) throws {
        let imported = try JSONDecoder().decode(ExportData.self, from: data)
        members = imported.members
        leaves = imported.leaves
        meetings = imported.meetings
        duties = imported.duties
        saveMembers()
        saveLeaves()
        saveMeetings()
        saveDuties()
    }

    func resetToPreset() {
        members = Self.presetMembers
        leaves = Self.presetLeaves
        meetings = Self.presetMeetings
        duties = []
        saveMembers()
        saveLeaves()
        saveMeetings()
        saveDuties()
    }

    // MARK: - Preset Data
    static let presetMembers: [Member] = [
        Member(id: 1, name: "曾煜凱", title: "工程師", sys: "Chemical", skill: "Slurry", grade: 31),
        Member(id: 2, name: "黃啓銘", title: "資深工程師", sys: "Chemical", skill: "Gas, Chemical", grade: 32),
        Member(id: 3, name: "鄭育承", title: "資深工程師", sys: "Chemical", skill: "Slurry, Chemical", grade: 32),
        Member(id: 4, name: "黃意超", title: "資深工程師", sys: "Chemical", skill: "Gas", grade: 32),
        Member(id: 5, name: "湯振廷", title: "工程師", sys: "Special Gas", skill: "Special Gas", grade: 31),
        Member(id: 6, name: "李其霖", title: "資深工程師", sys: "Waste Chemical", skill: "Chemical, Waste", grade: 32),
        Member(id: 7, name: "蔡亞宸", title: "工程師", sys: "Slurry", skill: "Slurry", grade: 31),
        Member(id: 8, name: "姚佳妤", title: "工程師", sys: "Chemical", skill: "Chemical", grade: 31),
        Member(id: 9, name: "張鉉台", title: "工程師", sys: "Slurry", skill: "Slurry", grade: 31),
        Member(id: 10, name: "郭子靖", title: "工程師", sys: "Slurry", skill: "Slurry", grade: 31),
        Member(id: 11, name: "李季恩", title: "工程師", sys: "Chemical", skill: "Chemical", grade: 31),
        Member(id: 12, name: "丁家立", title: "工程師", sys: "Chemical", skill: "Chemical", grade: 31),
    ]

    static let presetLeaves: [Leave] = [
        Leave(id: 1, name: "曾煜凱", type: "公假", from: "2026-04-13", to: "2026-04-13", days: 1, reason: "健檢"),
        Leave(id: 2, name: "黃意超", type: "公假", from: "2026-04-08", to: "2026-04-08", days: 0.5, reason: "體檢（下午）"),
        Leave(id: 3, name: "郭子靖", type: "病假", from: "2026-04-09", to: "2026-04-09", days: 1, reason: "回診左手脫臼"),
        Leave(id: 4, name: "丁家立", type: "事假", from: "2026-04-08", to: "2026-04-08", days: 0.5, reason: "15:30後請假"),
        Leave(id: 5, name: "鄭育承", type: "公假", from: "2026-04-10", to: "2026-04-10", days: 1, reason: "RPA 課程"),
        Leave(id: 6, name: "李其霖", type: "公假", from: "2026-04-27", to: "2026-04-29", days: 3, reason: "缺氧作業主管訓練"),
        Leave(id: 7, name: "蔡亞宸", type: "公假", from: "2026-04-10", to: "2026-04-10", days: 1, reason: "RPA 課程"),
    ]

    static let presetMeetings: [Meeting] = [
        Meeting(id: 1, date: "2026-04-07", name: "部門周會", time: "13:00–14:00", place: "會議室"),
        Meeting(id: 2, date: "2026-04-07", name: "部門月會", time: "15:00–16:00", place: "會議室"),
        Meeting(id: 3, date: "2026-04-08", name: "APM 會議", time: "09:30–10:30", place: "會議室"),
        Meeting(id: 4, date: "2026-04-10", name: "面試 — 李新（中正大學化學生化）", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 5, date: "2026-04-13", name: "面試 — 李品勳（中山化學）", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 6, date: "2026-04-16", name: "面試 — 孫梵凱（清大化工）", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 7, date: "2026-04-17", name: "面試 — 黃駿維（中興化工）", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 8, date: "2026-04-19", name: "🎉 小漢堡抓周 — 大溪威斯丁", time: "13:30–19:30", place: "大溪威斯丁飯店", note: "小漢堡人生第一次抓周！"),
    ]
}
