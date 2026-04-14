import SwiftUI

struct LeavesView: View {
    @EnvironmentObject var store: DataStore
    @State private var showForm = false
    @State private var editingLeave: Leave?

    // Column visibility (persisted)
    @AppStorage("leave_col_type") private var colType = true
    @AppStorage("leave_col_from") private var colFrom = true
    @AppStorage("leave_col_to") private var colTo = true
    @AppStorage("leave_col_days") private var colDays = true
    @AppStorage("leave_col_reason") private var colReason = true

    private var currentYear: Int { Calendar.current.component(.year, from: store.selectedDate) }
    private var currentMonth: Int { Calendar.current.component(.month, from: store.selectedDate) - 1 }

    private var monthLeaves: [Leave] {
        let ms = DateHelper.monthStr(year: currentYear, month: currentMonth)
        return store.leaves.filter { $0.from.hasPrefix(ms) || $0.to.hasPrefix(ms) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "🏖️", title: "請假記錄")

            // Date picker
            DatePickerCard(selectedDate: $store.selectedDate)
                .environmentObject(store)

            // Today's leaves card
            todayLeavesCard

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("請假列表")
                            .font(.system(size: 13, weight: .bold))
                        Text("\(String(currentYear))年\(DateHelper.months[currentMonth])（\(monthLeaves.count)筆）")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.muted)
                        Spacer()

                        // Field toggle
                        fieldMenuButton

                        Button("＋ 新增") {
                            editingLeave = nil
                            showForm = true
                        }
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.blue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                    }

                    if monthLeaves.isEmpty {
                        EmptyStateView(icon: "🏖️", message: "本月無請假記錄")
                    } else {
                        leaveTable
                    }
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
        .sheet(isPresented: $showForm, onDismiss: { editingLeave = nil }) {
            LeaveFormSheet(leave: editingLeave)
                .environmentObject(store)
        }
    }

    // MARK: - Today Leaves Card
    private var todayLeavesCard: some View {
        let ds = DateHelper.dateStr(store.selectedDate)
        let wd = DateHelper.weekdayLabel(store.selectedDate)
        let leavers = store.members.compactMap { m -> (Member, AttendanceStatus)? in
            let s = store.getStatus(name: m.name, dateStr: ds)
            if s.code != "present" && s.code != "holiday" && s.code != "duty" && s.code != "night-rest" {
                return (m, s)
            }
            return nil
        }

        return CardView(
            background: Color.clear,
            borderColor: Color(hex: "d29922").opacity(0.3)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🏖️ 當日請假人員")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "a07020"))
                        .kerning(2)
                    Spacer()
                    Text("\(ds)（\(wd)）")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "c09040"))
                }

                if leavers.isEmpty {
                    Text("當日全員出勤 🎉")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "c09040"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    let rows = stride(from: 0, to: leavers.count, by: 2).map { i in
                        Array(leavers[i..<min(i+2, leavers.count)])
                    }
                    VStack(spacing: 8) {
                        ForEach(rows, id: \.first!.0.id) { pair in
                            HStack(alignment: .top, spacing: 8) {
                                ForEach(pair, id: \.0.id) { (member, status) in
                                    LeaveMiniCard(member: member, status: status)
                                }
                                if pair.count == 1 {
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "fff8e1"), Color(hex: "fce4ec"), Color(hex: "f3e8ff")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(14)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        )
    }

    // MARK: - Field Menu
    private var fieldMenuButton: some View {
        Menu {
            Text("顯示欄位")
            Toggle("假別", isOn: $colType)
            Toggle("起始日期", isOn: $colFrom)
            Toggle("結束日期", isOn: $colTo)
            Toggle("天數", isOn: $colDays)
            Toggle("事由", isOn: $colReason)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gearshape")
                    .font(.system(size: 9))
                Text("顯示欄位")
                    .font(.system(size: 10))
            }
            .foregroundColor(AppTheme.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.paper)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
        }
    }

    // MARK: - Table
    private var leaveTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("員工").frame(width: 50, alignment: .leading)
                    if colType { Text("假別").frame(width: 50, alignment: .leading) }
                    if colFrom { Text("起始").frame(width: 80, alignment: .leading) }
                    if colTo { Text("結束").frame(width: 80, alignment: .leading) }
                    if colDays { Text("天數").frame(width: 40, alignment: .leading) }
                    if colReason { Text("事由").frame(width: 100, alignment: .leading) }
                    Text("").frame(width: 70)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.muted)
                .padding(.vertical, 7)
                .padding(.horizontal, 9)
                .background(AppTheme.paper)

                // Rows
                ForEach(monthLeaves) { l in
                    LeaveTableRow(
                        leave: l,
                        colType: colType, colFrom: colFrom, colTo: colTo,
                        colDays: colDays, colReason: colReason,
                        onEdit: {
                            editingLeave = l
                            showForm = true
                        },
                        onDelete: {
                            store.deleteLeave(l.id)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Leave Table Row
struct LeaveTableRow: View {
    let leave: Leave
    var colType: Bool = true
    var colFrom: Bool = true
    var colTo: Bool = true
    var colDays: Bool = true
    var colReason: Bool = true
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 0) {
            Text(leave.name)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 50, alignment: .leading)

            if colType {
                BadgeView(text: leave.type, style: BadgeStyle.forLeaveType(leave.type))
                    .frame(width: 50, alignment: .leading)
            }

            if colFrom {
                Text(leave.from)
                    .font(.system(size: 10))
                    .frame(width: 80, alignment: .leading)
            }

            if colTo {
                Text(leave.to)
                    .font(.system(size: 10))
                    .frame(width: 80, alignment: .leading)
            }

            if colDays {
                Text("\(leave.days, specifier: "%.1g")天")
                    .font(.system(size: 12))
                    .frame(width: 40, alignment: .leading)
            }

            if colReason {
                Text(leave.reason.isEmpty ? "–" : leave.reason)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.muted)
                    .frame(width: 100, alignment: .leading)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                SmallActionButton(title: "編", color: AppTheme.blue, action: onEdit)
                SmallActionButton(title: "刪", color: AppTheme.rust) {
                    showDeleteAlert = true
                }
            }
            .frame(width: 70)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 9)
        .overlay(Rectangle().fill(Color(hex: "f0ece4")).frame(height: 1), alignment: .bottom)
        .alert("確定刪除 \(leave.name) \(leave.from) 的請假記錄？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Leave Form Sheet
struct LeaveFormSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    var leave: Leave?

    @State private var selectedName = ""
    @State private var type = "公假"
    @State private var fromDate = DateHelper.today()
    @State private var toDate = DateHelper.today()
    @State private var days: Double = 1
    @State private var reason = ""
    @State private var startPeriod = "全天"  // 全天 / 上午 / 下午

    let daysOptions: [Double] = [0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6, 7, 10, 14]
    let periodOptions = ["全天", "上午", "下午"]

    var isEditing: Bool { leave != nil }

    /// Auto plant from selected member
    private var memberPlant: String {
        guard let m = store.members.first(where: { $0.name == selectedName }) else { return "–" }
        return m.plant ?? "未指定"
    }

    /// Auto-calculated end date
    private var calculatedToDate: String {
        guard let start = DateHelper.parseDate(fromDate) else { return fromDate }
        // For half day, end = start
        if days <= 0.5 { return fromDate }
        // Calculate working days to add (skip weekends)
        var wholeDays = Int(ceil(days)) - 1
        if startPeriod == "下午" && days == 1 {
            // Afternoon start + 1 day = next working day
            wholeDays = 1
        }
        var current = start
        var added = 0
        while added < wholeDays {
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
            if !DateHelper.isWeekend(current) {
                added += 1
            }
        }
        return DateHelper.dateStr(current)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("員工資訊")) {
                    Picker("員工姓名", selection: $selectedName) {
                        Text("選擇員工").tag("")
                        ForEach(store.members) { m in
                            Text(m.name).tag(m.name)
                        }
                    }

                    if !selectedName.isEmpty {
                        HStack {
                            Text("廠別")
                            Spacer()
                            Text(memberPlant)
                                .foregroundColor(AppTheme.muted)
                        }
                    }
                }

                Section(header: Text("假別與時段")) {
                    Picker("假別", selection: $type) {
                        ForEach(leaveTypeOptions, id: \.self) { Text($0) }
                    }

                    Picker("時段", selection: $startPeriod) {
                        ForEach(periodOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: startPeriod) { newVal in
                        if newVal == "上午" || newVal == "下午" {
                            if days >= 1 { /* keep */ } else { days = 0.5 }
                        }
                        recalcEndDate()
                    }
                }

                Section(header: Text("日期與天數")) {
                    DatePicker("起始日期", selection: Binding(
                        get: { DateHelper.parseDate(fromDate) ?? Date() },
                        set: {
                            fromDate = DateHelper.dateStr($0)
                            recalcEndDate()
                        }
                    ), displayedComponents: .date)

                    Picker("天數", selection: $days) {
                        ForEach(daysOptions, id: \.self) { d in
                            Text(d == Double(Int(d)) ? "\(Int(d)) 天" : "\(d, specifier: "%.1f") 天").tag(d)
                        }
                    }
                    .onChange(of: days) { _ in recalcEndDate() }

                    HStack {
                        Text("結束日期")
                        Spacer()
                        Text(toDate)
                            .foregroundColor(AppTheme.muted)
                    }

                    if startPeriod != "全天" {
                        HStack {
                            Text("備註")
                            Spacer()
                            Text(startPeriod == "上午" ? "上午請假（08:30–12:00）" : "下午請假（13:00–17:30）")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.blue)
                        }
                    }
                }

                Section(header: Text("事由")) {
                    TextField("健檢 / RPA課程...", text: $reason)
                }
            }
            .navigationTitle(isEditing ? "編輯請假" : "新增請假")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveLeave() }
                        .disabled(selectedName.isEmpty || fromDate.isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    private func recalcEndDate() {
        toDate = calculatedToDate
    }

    private func loadData() {
        if let l = leave {
            selectedName = l.name
            type = l.type
            fromDate = l.from
            toDate = l.to
            days = l.days
            reason = l.reason
            // Infer period from days
            if l.days == 0.5 {
                if l.reason.contains("下午") || l.reason.contains("午後") {
                    startPeriod = "下午"
                } else if l.reason.contains("上午") {
                    startPeriod = "上午"
                }
            }
        } else {
            fromDate = DateHelper.dateStr(store.selectedDate)
            recalcEndDate()
        }
    }

    private func saveLeave() {
        toDate = calculatedToDate
        if var l = leave {
            l.name = selectedName
            l.type = type
            l.from = fromDate
            l.to = toDate
            l.days = days
            l.reason = reason
            store.updateLeave(l)
        } else {
            let l = Leave(id: store.newId(), name: selectedName, type: type, from: fromDate, to: toDate, days: days, reason: reason)
            store.addLeave(l)
        }
        dismiss()
    }
}
