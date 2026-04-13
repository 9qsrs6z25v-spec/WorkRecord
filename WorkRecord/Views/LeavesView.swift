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

    var isEditing: Bool { leave != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("請假資訊")) {
                    Picker("員工姓名", selection: $selectedName) {
                        Text("選擇員工").tag("")
                        ForEach(store.members) { m in
                            Text(m.name).tag(m.name)
                        }
                    }

                    Picker("假別", selection: $type) {
                        ForEach(leaveTypeOptions, id: \.self) { Text($0) }
                    }

                    HStack {
                        Text("天數")
                        Spacer()
                        TextField("1", value: $days, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                    }
                }

                Section(header: Text("日期")) {
                    DatePicker("起始日期", selection: Binding(
                        get: { DateHelper.parseDate(fromDate) ?? Date() },
                        set: { fromDate = DateHelper.dateStr($0) }
                    ), displayedComponents: .date)

                    DatePicker("結束日期", selection: Binding(
                        get: { DateHelper.parseDate(toDate) ?? Date() },
                        set: { toDate = DateHelper.dateStr($0) }
                    ), displayedComponents: .date)
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
                        .disabled(selectedName.isEmpty || fromDate.isEmpty || toDate.isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        if let l = leave {
            selectedName = l.name
            type = l.type
            fromDate = l.from
            toDate = l.to
            days = l.days
            reason = l.reason
        } else {
            fromDate = DateHelper.dateStr(store.selectedDate)
            toDate = DateHelper.dateStr(store.selectedDate)
        }
    }

    private func saveLeave() {
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
