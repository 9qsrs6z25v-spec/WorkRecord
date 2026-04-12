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

    // MARK: - iCloud Sync State
    @Published var iCloudEnabled: Bool = false
    @Published var lastSyncTime: Date? = nil

    // MARK: - Keys
    private let membersKey = "fg2_members"
    private let leavesKey = "fg2_leaves"
    private let meetingsKey = "fg2_meetings"
    private let dutyKey = "fg2_duty"
    private let versionKey = "fg2_app_version"
    private let appVersion = "v3_work_only"
    private let lastSyncKey = "fg2_last_sync"

    private let iCloud = NSUbiquitousKeyValueStore.default

    // MARK: - Init
    init() {
        checkVersion()
        setupiCloudSync()
        loadAll()
    }

    // MARK: - iCloud Setup
    private func setupiCloudSync() {
        // Check if iCloud is available
        if FileManager.default.ubiquityIdentityToken != nil {
            iCloudEnabled = true

            // Listen for remote changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(iCloudDidChange),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: iCloud
            )

            // Force initial sync
            iCloud.synchronize()
        }
    }

    @objc private func iCloudDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.mergeFromiCloud()
        }
    }

    /// Pull data from iCloud (remote wins if newer)
    private func mergeFromiCloud() {
        let remoteSync = iCloud.object(forKey: lastSyncKey) as? Double ?? 0
        let localSync = UserDefaults.standard.double(forKey: lastSyncKey)

        // Only overwrite local if remote is newer
        guard remoteSync > localSync else { return }

        if let data = iCloud.data(forKey: membersKey),
           let decoded = try? JSONDecoder().decode([Member].self, from: data) {
            members = decoded
            saveLocal(key: membersKey, data: members)
        }
        if let data = iCloud.data(forKey: leavesKey),
           let decoded = try? JSONDecoder().decode([Leave].self, from: data) {
            leaves = decoded
            saveLocal(key: leavesKey, data: leaves)
        }
        if let data = iCloud.data(forKey: meetingsKey),
           let decoded = try? JSONDecoder().decode([Meeting].self, from: data) {
            meetings = decoded
            saveLocal(key: meetingsKey, data: meetings)
        }
        if let data = iCloud.data(forKey: dutyKey),
           let decoded = try? JSONDecoder().decode([Duty].self, from: data) {
            duties = decoded
            saveLocal(key: dutyKey, data: duties)
        }

        UserDefaults.standard.set(remoteSync, forKey: lastSyncKey)
        lastSyncTime = Date(timeIntervalSince1970: remoteSync)
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
        // Try iCloud first, then local, then preset
        members = loadLocal(key: membersKey) ?? loadiCloud(key: membersKey) ?? Self.presetMembers
        leaves = loadLocal(key: leavesKey) ?? loadiCloud(key: leavesKey) ?? Self.presetLeaves
        meetings = loadLocal(key: meetingsKey) ?? loadiCloud(key: meetingsKey) ?? Self.presetMeetings
        duties = loadLocal(key: dutyKey) ?? loadiCloud(key: dutyKey) ?? []

        // Ensure saved locally
        saveLocal(key: membersKey, data: members)
        saveLocal(key: leavesKey, data: leaves)
        saveLocal(key: meetingsKey, data: meetings)
        saveLocal(key: dutyKey, data: duties)

        // Push to iCloud if first time
        pushToiCloud()
    }

    // MARK: - Local Persistence
    private func loadLocal<T: Codable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveLocal<T: Codable>(key: String, data: T) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    // MARK: - iCloud Persistence
    private func loadiCloud<T: Codable>(key: String) -> T? {
        guard iCloudEnabled, let data = iCloud.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveiCloud<T: Codable>(key: String, data: T) {
        guard iCloudEnabled else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            iCloud.set(encoded, forKey: key)
        }
    }

    private func pushToiCloud() {
        guard iCloudEnabled else { return }
        saveiCloud(key: membersKey, data: members)
        saveiCloud(key: leavesKey, data: leaves)
        saveiCloud(key: meetingsKey, data: meetings)
        saveiCloud(key: dutyKey, data: duties)
        let now = Date().timeIntervalSince1970
        iCloud.set(now, forKey: lastSyncKey)
        UserDefaults.standard.set(now, forKey: lastSyncKey)
        iCloud.synchronize()
        lastSyncTime = Date()
    }

    // MARK: - Save (local + iCloud)
    private func save<T: Codable>(key: String, data: T) {
        saveLocal(key: key, data: data)
        saveiCloud(key: key, data: data)
        let now = Date().timeIntervalSince1970
        iCloud.set(now, forKey: lastSyncKey)
        UserDefaults.standard.set(now, forKey: lastSyncKey)
        if iCloudEnabled { iCloud.synchronize() }
        lastSyncTime = Date()
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
        Member(id: 1, name: "王大明", title: "工程師", sys: "Chemical", skill: "Slurry", grade: "31"),
        Member(id: 2, name: "陳志豪", title: "資深工程師", sys: "Chemical", skill: "Gas, Chemical", grade: "32"),
        Member(id: 3, name: "林俊宏", title: "資深工程師", sys: "Chemical", skill: "Slurry, Chemical", grade: "32"),
        Member(id: 4, name: "張書維", title: "資深工程師", sys: "Chemical", skill: "Gas", grade: "32"),
        Member(id: 5, name: "劉冠廷", title: "工程師", sys: "Special Gas", skill: "Special Gas", grade: "31"),
        Member(id: 6, name: "李宗翰", title: "資深工程師", sys: "Waste Chemical", skill: "Chemical, Waste", grade: "32"),
        Member(id: 7, name: "蔡柏翔", title: "工程師", sys: "Slurry", skill: "Slurry", grade: "31"),
        Member(id: 8, name: "吳佳穎", title: "工程師", sys: "Chemical", skill: "Chemical", grade: "31"),
        Member(id: 9, name: "周建宇", title: "工程師", sys: "Slurry", skill: "Slurry", grade: "31"),
        Member(id: 10, name: "許家銘", title: "工程師", sys: "Slurry", skill: "Slurry", grade: "31"),
        Member(id: 11, name: "楊承翰", title: "工程師", sys: "Chemical", skill: "Chemical", grade: "31"),
        Member(id: 12, name: "趙韋廷", title: "工程師", sys: "Chemical", skill: "Chemical", grade: "31"),
    ]

    static let presetLeaves: [Leave] = [
        Leave(id: 1, name: "王大明", type: "公假", from: "2026-04-13", to: "2026-04-13", days: 1, reason: "健檢"),
        Leave(id: 2, name: "張書維", type: "公假", from: "2026-04-08", to: "2026-04-08", days: 0.5, reason: "體檢（下午）"),
        Leave(id: 3, name: "許家銘", type: "病假", from: "2026-04-09", to: "2026-04-09", days: 1, reason: "回診"),
        Leave(id: 4, name: "趙韋廷", type: "事假", from: "2026-04-08", to: "2026-04-08", days: 0.5, reason: "15:30後請假"),
        Leave(id: 5, name: "林俊宏", type: "公假", from: "2026-04-10", to: "2026-04-10", days: 1, reason: "RPA 課程"),
        Leave(id: 6, name: "李宗翰", type: "公假", from: "2026-04-27", to: "2026-04-29", days: 3, reason: "安全衛生訓練"),
        Leave(id: 7, name: "蔡柏翔", type: "公假", from: "2026-04-10", to: "2026-04-10", days: 1, reason: "RPA 課程"),
    ]

    static let presetMeetings: [Meeting] = [
        Meeting(id: 1, date: "2026-04-07", name: "部門周會", time: "13:00–14:00", place: "會議室"),
        Meeting(id: 2, date: "2026-04-07", name: "部門月會", time: "15:00–16:00", place: "會議室"),
        Meeting(id: 3, date: "2026-04-08", name: "APM 會議", time: "09:30–10:30", place: "會議室"),
        Meeting(id: 4, date: "2026-04-10", name: "新人面試 — A候選人", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 5, date: "2026-04-13", name: "新人面試 — B候選人", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 6, date: "2026-04-16", name: "新人面試 — C候選人", time: "10:00–11:00", place: "會議室"),
        Meeting(id: 7, date: "2026-04-17", name: "設備維護討論會", time: "14:00–15:00", place: "會議室"),
        Meeting(id: 8, date: "2026-04-19", name: "部門團建活動", time: "13:30–17:00", place: "園區餐廳", note: "季度團建聚餐"),
    ]
}
