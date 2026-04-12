import SwiftUI

struct DatePickerCard: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedDate: Date
    @State private var showCalendar = false

    var body: some View {
        CardView(background: AppTheme.ink, borderColor: AppTheme.gold.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("📅 選擇查詢日期")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.gold2)
                    .kerning(2)

                // Date display
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(DateHelper.dateStr(selectedDate))
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .kerning(1)
                    Text("（\(DateHelper.weekdayLabel(selectedDate))）\(DateHelper.isWeekend(selectedDate) ? " 例假日" : "")")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.gold)
                }

                // Quick buttons
                quickButtons

                // Calendar toggle
                calendarToggle
            }
        }
    }

    private var quickButtons: some View {
        let todayDate = DateHelper.todayDate()
        let diff = Calendar.current.dateComponents([.day], from: todayDate, to: Calendar.current.startOfDay(for: selectedDate)).day ?? 0

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                QuickDateButton(label: "前天", isSelected: diff == -2) {
                    selectedDate = DateHelper.addDays(todayDate, -2)
                }
                QuickDateButton(label: "昨天", isSelected: diff == -1) {
                    selectedDate = DateHelper.addDays(todayDate, -1)
                }
                QuickDateButton(label: "今天", isSelected: diff == 0) {
                    selectedDate = todayDate
                }
                QuickDateButton(label: "明天", isSelected: diff == 1) {
                    selectedDate = DateHelper.addDays(todayDate, 1)
                }
                QuickDateButton(label: "後天", isSelected: diff == 2) {
                    selectedDate = DateHelper.addDays(todayDate, 2)
                }
                QuickDateButton(label: "本週五", isSelected: false, isSpecial: true) {
                    selectedDate = DateHelper.jumpToWeekday(6)
                }
                QuickDateButton(label: "下週一", isSelected: false, isSpecial: true) {
                    selectedDate = DateHelper.jumpToWeekday(2)
                }
            }
        }

    }

    private var calendarToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { showCalendar.toggle() } }) {
                HStack(spacing: 7) {
                    Text("📆")
                    Text("月曆選日期")
                        .font(.system(size: 11))
                    Text(showCalendar ? "▲" : "▼")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.07))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            if showCalendar {
                MiniCalendarView(selectedDate: $selectedDate, showCalendar: $showCalendar)
                    .environmentObject(store)
            }
        }
    }
}

struct MiniCalendarView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool
    @State private var calY: Int = Calendar.current.component(.year, from: Date())
    @State private var calM: Int = Calendar.current.component(.month, from: Date()) - 1

    var body: some View {
        VStack(spacing: 10) {
            // Nav
            HStack {
                Button(action: { calNav(-1) }) {
                    Text("‹")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                Spacer()
                Text("\(String(calY)) 年 \(DateHelper.months[calM])")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { calNav(1) }) {
                    Text("›")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
            }

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 9))
                        .foregroundColor(d == "日" ? Color(hex: "f85149") : (d == "六" ? Color(hex: "388bfd") : Color(hex: "7d8590")))
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            let dim = DateHelper.daysInMonth(year: calY, month: calM)
            let firstW = DateHelper.firstWeekdayOfMonth(year: calY, month: calM)
            let todayStr = DateHelper.today()
            let selStr = DateHelper.dateStr(selectedDate)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(0..<firstW, id: \.self) { _ in
                    Text("").frame(height: 30)
                }
                ForEach(1...dim, id: \.self) { day in
                    let ds = String(format: "%d-%02d-%02d", calY, calM + 1, day)
                    let isWE = DateHelper.isWeekend(ds)
                    let isToday = ds == todayStr
                    let isSel = ds == selStr
                    let hasLeave = store.leaves.contains { l in
                        guard let f = DateHelper.parseDate(l.from),
                              let t = DateHelper.parseDate(l.to),
                              let d2 = DateHelper.parseDate(ds) else { return false }
                        return d2 >= f && d2 <= t
                    }

                    Button(action: {
                        if !isWE {
                            selectedDate = DateHelper.parseDate(ds) ?? selectedDate
                            showCalendar = false
                        }
                    }) {
                        ZStack {
                            Text("\(day)")
                                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                                .foregroundColor(
                                    isSel ? .white :
                                    isToday ? AppTheme.gold :
                                    isWE ? Color.white.opacity(0.25) :
                                    Color.white.opacity(0.7)
                                )
                                .frame(width: 30, height: 30)
                                .background(isSel ? AppTheme.blue : Color.clear)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isToday && !isSel ? AppTheme.gold : Color.clear, lineWidth: 1)
                                )
                            if hasLeave {
                                Circle()
                                    .fill(Color(hex: "d29922"))
                                    .frame(width: 4, height: 4)
                                    .offset(y: 11)
                            }
                        }
                    }
                    .disabled(isWE)
                }
            }
        }
        .padding(14)
        .background(Color(hex: "1c2128"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func calNav(_ dir: Int) {
        calM += dir
        if calM > 11 { calM = 0; calY += 1 }
        if calM < 0 { calM = 11; calY -= 1 }
    }
}
