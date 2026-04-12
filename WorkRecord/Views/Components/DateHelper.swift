import Foundation

struct DateHelper {
    static let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    static let months = ["一月", "二月", "三月", "四月", "五月", "六月",
                          "七月", "八月", "九月", "十月", "十一月", "十二月"]

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_TW")
        return f
    }()

    static func dateStr(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func parseDate(_ str: String) -> Date? {
        formatter.date(from: str)
    }

    static func isWeekend(_ dateStr: String) -> Bool {
        guard let d = parseDate(dateStr) else { return false }
        let w = Calendar.current.component(.weekday, from: d)
        return w == 1 || w == 7
    }

    static func isWeekend(_ date: Date) -> Bool {
        let w = Calendar.current.component(.weekday, from: date)
        return w == 1 || w == 7
    }

    static func weekdayLabel(_ date: Date) -> String {
        let w = Calendar.current.component(.weekday, from: date)
        return weekdays[w - 1]
    }

    static func weekdayLabel(_ dateStr: String) -> String {
        guard let d = parseDate(dateStr) else { return "" }
        return weekdayLabel(d)
    }

    static func addDays(_ dateStr: String, _ n: Int) -> String {
        guard let d = parseDate(dateStr) else { return dateStr }
        guard let result = Calendar.current.date(byAdding: .day, value: n, to: d) else { return dateStr }
        return self.dateStr(result)
    }

    static func addDays(_ date: Date, _ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: date) ?? date
    }

    static func todayDate() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    static func today() -> String {
        dateStr(todayDate())
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        let comps = DateComponents(year: year, month: month + 1) // 0-based month, +1 for next
        guard let date = Calendar.current.date(from: comps) else { return 30 }
        // Get last day of month
        let range = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(byAdding: .month, value: -1, to: date)!)
        return range?.count ?? 30
    }

    static func firstWeekdayOfMonth(year: Int, month: Int) -> Int {
        // month is 0-based
        let comps = DateComponents(year: year, month: month + 1, day: 1)
        guard let date = Calendar.current.date(from: comps) else { return 0 }
        return Calendar.current.component(.weekday, from: date) - 1 // 0=Sun
    }

    static func monthStr(year: Int, month: Int) -> String {
        "\(year)-\(String(format: "%02d", month + 1))"
    }

    static func jumpToWeekday(_ target: Int, fromToday: Bool = true) -> Date {
        let d = todayDate()
        let current = Calendar.current.component(.weekday, from: d) // 1=Sun, 2=Mon...
        var diff = target - current
        if target == 2 && diff <= 0 { diff += 7 } // Monday: next week
        if target == 6 && diff < 0 { diff += 7 }  // Friday: this week or next
        return addDays(d, diff)
    }

    static func calcEndTime(start: String, durationMinutes: Int) -> String {
        let parts = start.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return "" }
        let totalMin = parts[0] * 60 + parts[1] + durationMinutes
        let eh = (totalMin / 60) % 24
        let em = totalMin % 60
        return String(format: "%02d:%02d", eh, em)
    }

    // Night shift schedule calculation
    static func calcNightSchedule(startDate: String) -> [(date: String, shift: String, isRest: Bool, isNight: Bool)] {
        var records: [(date: String, shift: String, isRest: Bool, isNight: Bool)] = []

        // D: rest day
        records.append((date: startDate, shift: "休假（夜班備班）", isRest: true, isNight: false))

        // D+1 ~ D+6: 6 duty days
        for i in 1...6 {
            let d = addDays(startDate, i)
            if isWeekend(d) {
                records.append((date: d, shift: "20:30–08:30（夜班/假日）", isRest: false, isNight: true))
            } else {
                records.append((date: d, shift: "00:00–08:30（夜班/平日）", isRest: false, isNight: true))
            }
        }

        // D+7: rest day (adjust timezone)
        records.append((date: addDays(startDate, 7), shift: "休假（調整時差）", isRest: true, isNight: false))

        return records
    }

    // Evening shift schedule
    static func calcEveSchedule(startDate: String) -> [(date: String, shift: String)] {
        (0..<5).map { i in
            (date: addDays(startDate, i), shift: "15:30–23:59（小夜班）")
        }
    }
}
