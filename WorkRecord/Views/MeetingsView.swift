import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showForm = false
    @State private var editingMeeting: Meeting?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "📝", title: "會議記錄")

            // Date picker
            meetingDatePicker

            // Today's meetings card
            todayMeetingsCard

            // All meetings
            allMeetingsCard
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
        .sheet(isPresented: $showForm, onDismiss: { editingMeeting = nil }) {
            MeetingFormSheet(meeting: editingMeeting)
                .environmentObject(store)
        }
    }

    // MARK: - Date Picker
    private var meetingDatePicker: some View {
        let todayDate = DateHelper.todayDate()
        let diff = Calendar.current.dateComponents([.day], from: todayDate, to: Calendar.current.startOfDay(for: store.selectedDate)).day ?? 0

        return CardView(background: AppTheme.ink, borderColor: AppTheme.gold.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("📅 選擇日期")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.gold2)
                    .kerning(2)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(DateHelper.dateStr(store.selectedDate))
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                    Text("（\(DateHelper.weekdayLabel(store.selectedDate))）\(DateHelper.isWeekend(store.selectedDate) ? " 例假日" : "")")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.gold)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        QuickDateButton(label: "前天", isSelected: diff == -2) {
                            store.selectedDate = DateHelper.addDays(todayDate, -2)
                        }
                        QuickDateButton(label: "昨天", isSelected: diff == -1) {
                            store.selectedDate = DateHelper.addDays(todayDate, -1)
                        }
                        QuickDateButton(label: "今天", isSelected: diff == 0) {
                            store.selectedDate = todayDate
                        }
                        QuickDateButton(label: "明天", isSelected: diff == 1) {
                            store.selectedDate = DateHelper.addDays(todayDate, 1)
                        }
                        QuickDateButton(label: "後天", isSelected: diff == 2) {
                            store.selectedDate = DateHelper.addDays(todayDate, 2)
                        }
                        QuickDateButton(label: "本週五", isSelected: false, isSpecial: true) {
                            store.selectedDate = DateHelper.jumpToWeekday(6)
                        }
                        QuickDateButton(label: "下週一", isSelected: false, isSpecial: true) {
                            store.selectedDate = DateHelper.jumpToWeekday(2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Meetings
    private var todayMeetingsCard: some View {
        let ds = DateHelper.dateStr(store.selectedDate)
        let wd = DateHelper.weekdayLabel(store.selectedDate)
        let todayMtgs = store.meetings.filter { $0.date == ds }.sorted { $0.time < $1.time }

        return CardView(
            background: Color.clear,
            borderColor: Color(hex: "b48cdc").opacity(0.3)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("📅 當日會議")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "7c4daa"))
                        .kerning(2)
                    Spacer()
                    Text("\(ds)（\(wd)）")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "a07cc0"))
                }

                if todayMtgs.isEmpty {
                    Text("當日無會議安排")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "b09cc0"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(todayMtgs) { m in
                            MeetingMiniCard(meeting: m)
                        }
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "f3e8ff"), Color(hex: "fce4ec"), Color(hex: "e8f5e9")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(14)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        )
    }

    // MARK: - All Meetings
    private var allMeetingsCard: some View {
        let sorted = store.meetings.sorted { $0.date > $1.date }

        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("全部會議記錄")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Button("＋ 新增") {
                        editingMeeting = nil
                        showForm = true
                    }
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.blue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                }

                if sorted.isEmpty {
                    EmptyStateView(icon: "📝", message: "尚無會議記錄")
                } else {
                    ForEach(sorted) { m in
                        MeetingRow(meeting: m, onEdit: {
                            editingMeeting = m
                            showForm = true
                        }, onDelete: {
                            store.deleteMeeting(m.id)
                        })
                    }
                }
            }
        }
    }
}

// MARK: - Meeting Row
struct MeetingRow: View {
    let meeting: Meeting
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Circle()
                .fill(AppTheme.blue)
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(meeting.date)
                    if !meeting.time.isEmpty { Text("· \(meeting.time)") }
                    if !meeting.place.isEmpty { Text("· \(meeting.place)") }
                }
                .font(.system(size: 10))
                .foregroundColor(AppTheme.muted)

                if !meeting.note.isEmpty {
                    Text(meeting.note)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "5a5448"))
                }
            }

            Spacer()

            HStack(spacing: 4) {
                SmallActionButton(title: "編", color: AppTheme.blue, action: onEdit)
                SmallActionButton(title: "刪", color: AppTheme.rust) {
                    showDeleteAlert = true
                }
            }
        }
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(Color(hex: "f0ece4")).frame(height: 1), alignment: .bottom)
        .alert("確定刪除？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Meeting Form Sheet
struct MeetingFormSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    var meeting: Meeting?

    @State private var date = DateHelper.today()
    @State private var name = ""
    @State private var startTime = "09:00"
    @State private var duration = 60
    @State private var place = "AP6A"
    @State private var note = ""

    var isEditing: Bool { meeting != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("會議資訊")) {
                    DatePicker("日期", selection: Binding(
                        get: { DateHelper.parseDate(date) ?? Date() },
                        set: { date = DateHelper.dateStr($0) }
                    ), displayedComponents: .date)

                    TextField("會議名稱", text: $name)

                    HStack {
                        Text("開始時間")
                        Spacer()
                        TextField("09:00", text: $startTime)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    Picker("會議長度", selection: $duration) {
                        ForEach(meetingDurationOptions, id: \.1) { opt in
                            Text(opt.0).tag(opt.1)
                        }
                    }

                    HStack {
                        Text("結束時間")
                        Spacer()
                        Text(DateHelper.calcEndTime(start: startTime, durationMinutes: duration))
                            .foregroundColor(AppTheme.muted)
                    }

                    Picker("地點", selection: $place) {
                        ForEach(meetingPlaceOptions, id: \.self) { Text($0) }
                    }

                    TextField("議程/說明", text: $note)
                }
            }
            .navigationTitle(isEditing ? "編輯會議" : "新增會議")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveMeeting() }
                        .disabled(name.isEmpty || date.isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        if let m = meeting {
            date = m.date
            name = m.name
            place = m.place
            note = m.note
            if !m.time.isEmpty {
                let parts = m.time.split(separator: "–").map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    startTime = parts[0]
                    let sp = parts[0].split(separator: ":").compactMap { Int($0) }
                    let ep = parts[1].split(separator: ":").compactMap { Int($0) }
                    if sp.count == 2 && ep.count == 2 {
                        let dur = (ep[0] * 60 + ep[1]) - (sp[0] * 60 + sp[1])
                        let opts = [30, 60, 90, 120, 180, 240]
                        duration = opts.min(by: { abs($0 - dur) < abs($1 - dur) }) ?? 60
                    }
                }
            }
        }
    }

    private func saveMeeting() {
        let endTime = DateHelper.calcEndTime(start: startTime, durationMinutes: duration)
        let time = "\(startTime)–\(endTime)"
        if var m = meeting {
            m.date = date
            m.name = name
            m.time = time
            m.place = place
            m.note = note
            store.updateMeeting(m)
        } else {
            let m = Meeting(id: store.newId(), date: date, name: name, time: time, place: place, note: note)
            store.addMeeting(m)
        }
        dismiss()
    }
}
