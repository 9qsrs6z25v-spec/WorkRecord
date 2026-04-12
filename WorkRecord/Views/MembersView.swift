import SwiftUI

struct MembersView: View {
    @EnvironmentObject var store: DataStore
    @State private var showForm = false
    @State private var editingMember: Member?
    @State private var showFieldMenu = false

    // Sorting
    @State private var sortColumn: String = ""
    @State private var sortAsc: Bool = true

    // Column visibility (persisted)
    @AppStorage("mem_col_title") private var colTitle = true
    @AppStorage("mem_col_sys") private var colSys = true
    @AppStorage("mem_col_skill") private var colSkill = true
    @AppStorage("mem_col_grade") private var colGrade = true
    @AppStorage("mem_col_plant") private var colPlant = false
    @AppStorage("mem_col_duty") private var colDuty = true

    // Sorted members
    private var sortedMembers: [Member] {
        guard !sortColumn.isEmpty else { return store.members }
        return store.members.sorted { a, b in
            let cmp: Int
            switch sortColumn {
            case "姓名":
                cmp = a.name.localizedCompare(b.name) == .orderedAscending ? -1 : 1
            case "職稱":
                let order = ["部經理", "經理", "副理", "主任工程師", "資深工程師", "工程師"]
                let ai = order.firstIndex(of: a.title) ?? order.count
                let bi = order.firstIndex(of: b.title) ?? order.count
                cmp = ai < bi ? -1 : (ai > bi ? 1 : 0)
            case "系統":
                cmp = (a.sys).localizedCompare(b.sys) == .orderedAscending ? -1 : 1
            case "技能":
                cmp = (a.skill).localizedCompare(b.skill) == .orderedAscending ? -1 : 1
            case "職等":
                let gradeOrder = ["36", "35", "34", "33M", "33", "32", "31"]
                let ai = gradeOrder.firstIndex(of: a.grade ?? "31") ?? gradeOrder.count
                let bi = gradeOrder.firstIndex(of: b.grade ?? "31") ?? gradeOrder.count
                cmp = ai < bi ? -1 : (ai > bi ? 1 : 0)
            case "廠區":
                cmp = (a.plant ?? "").localizedCompare(b.plant ?? "") == .orderedAscending ? -1 : 1
            case "值班考核":
                cmp = (a.dutyPass ? 0 : 1) - (b.dutyPass ? 0 : 1)
            default:
                cmp = 0
            }
            return sortAsc ? cmp < 0 : cmp > 0
        }
    }

    private func toggleSort(_ col: String) {
        if sortColumn == col {
            sortAsc.toggle()
        } else {
            sortColumn = col
            sortAsc = true
        }
    }

    private func sortIndicator(_ col: String) -> String {
        if sortColumn == col {
            return sortAsc ? " ▲" : " ▼"
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "👥", title: "部門成員", subtitle: "（\(store.members.count) 人）")

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("成員列表")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()

                        // Field toggle button
                        fieldMenuButton

                        Button("＋ 新增成員") {
                            editingMember = nil
                            showForm = true
                        }
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.blue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                    }

                    memberTable
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
        .sheet(isPresented: $showForm, onDismiss: { editingMember = nil }) {
            MemberFormSheet(member: editingMember)
                .environmentObject(store)
        }
    }

    // MARK: - Field Menu
    private var fieldMenuButton: some View {
        Menu {
            Text("表格顯示欄位")
            Toggle("職稱", isOn: $colTitle)
            Toggle("系統", isOn: $colSys)
            Toggle("技能", isOn: $colSkill)
            Toggle("職等", isOn: $colGrade)
            Toggle("廠區", isOn: $colPlant)
            Toggle("值班考核", isOn: $colDuty)
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

    // MARK: - Sortable Header
    private func sortableHeader(_ label: String, width: CGFloat, alignment: Alignment = .leading) -> some View {
        Button(action: { toggleSort(label) }) {
            Text("\(label)\(sortIndicator(label))")
                .frame(width: width, alignment: alignment)
                .foregroundColor(sortColumn == label ? AppTheme.ink : AppTheme.muted)
        }
    }

    // MARK: - Table
    private var memberTable: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("序").frame(width: 25, alignment: .leading)
                        sortableHeader("姓名", width: 55)
                        if colTitle { sortableHeader("職稱", width: 70) }
                        if colSys { sortableHeader("系統", width: 70) }
                        if colSkill { sortableHeader("技能", width: 90) }
                        if colGrade { sortableHeader("職等", width: 35) }
                        if colPlant { sortableHeader("廠區", width: 50) }
                        if colDuty { sortableHeader("值班考核", width: 65, alignment: .center) }
                        Spacer()
                    }
                    .font(.system(size: 10, weight: .medium))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 9)
                    .background(AppTheme.paper)

                    // Rows
                    ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { idx, m in
                        MemberTableRow(
                            index: idx + 1, member: m,
                            colTitle: colTitle, colSys: colSys, colSkill: colSkill,
                            colGrade: colGrade, colPlant: colPlant, colDuty: colDuty,
                            onEdit: {
                                editingMember = m
                                showForm = true
                            },
                            onDelete: {
                                store.deleteMember(m.id)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Member Table Row
struct MemberTableRow: View {
    let index: Int
    let member: Member
    var colTitle: Bool = true
    var colSys: Bool = true
    var colSkill: Bool = true
    var colGrade: Bool = true
    var colPlant: Bool = false
    var colDuty: Bool = true
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 0) {
            Text("\(index)").frame(width: 25, alignment: .leading)
                .font(.system(size: 12))

            Text(member.name)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 55, alignment: .leading)

            if colTitle {
                Text(member.title)
                    .font(.system(size: 12))
                    .frame(width: 70, alignment: .leading)
            }

            if colSys {
                Text(member.sys.isEmpty ? "–" : member.sys)
                    .font(.system(size: 12))
                    .frame(width: 70, alignment: .leading)
                    .lineLimit(1)
            }

            if colSkill {
                Text(member.skill.isEmpty ? "–" : member.skill)
                    .font(.system(size: 12))
                    .frame(width: 90, alignment: .leading)
                    .lineLimit(1)
            }

            if colGrade {
                Text(member.grade ?? "–")
                    .font(.system(size: 12))
                    .frame(width: 35, alignment: .leading)
            }

            if colPlant {
                Text(member.plant ?? "–")
                    .font(.system(size: 12))
                    .frame(width: 50, alignment: .leading)
            }

            if colDuty {
                HStack {
                    if member.dutyPass {
                        BadgeView(text: "通過", style: BadgeStyle(
                            bg: Color(hex: "e8f5ee"), fg: AppTheme.sage, border: Color(hex: "b5ddc5")))
                    } else {
                        BadgeView(text: "未通過", style: BadgeStyle(
                            bg: Color(hex: "f5f0e8"), fg: AppTheme.muted, border: AppTheme.border))
                    }
                }
                .frame(width: 65, alignment: .center)
            }

            Spacer()

            HStack(spacing: 4) {
                SmallActionButton(title: "編", color: AppTheme.blue, action: onEdit)
                SmallActionButton(title: "刪", color: AppTheme.rust) {
                    showDeleteAlert = true
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 9)
        .overlay(Rectangle().fill(Color(hex: "f0ece4")).frame(height: 1), alignment: .bottom)
        .alert("確定刪除？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Member Form Sheet
struct MemberFormSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    var member: Member?

    @State private var name = ""
    @State private var title = "工程師"
    @State private var sys = ""
    @State private var skill = ""
    @State private var grade = "31"
    @State private var plant = ""
    @State private var dutyPass = false

    var isEditing: Bool { member != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資訊")) {
                    TextField("姓名", text: $name)

                    Picker("職等", selection: $grade) {
                        ForEach(gradeOptions, id: \.self) { g in
                            Text("\(g) — \(titleForGrade(g))").tag(g)
                        }
                    }
                    .onChange(of: grade) { newGrade in
                        title = titleForGrade(newGrade)
                    }

                    HStack {
                        Text("職稱")
                        Spacer()
                        Text(title)
                            .foregroundColor(AppTheme.muted)
                    }

                    TextField("系統 (如 Chemical)", text: $sys)
                    TextField("技能 (如 Slurry)", text: $skill)
                }

                Section(header: Text("廠區與考核")) {
                    Picker("廠區", selection: $plant) {
                        Text("未指定").tag("")
                        Text("AP6A").tag("AP6A")
                        Text("AP6B").tag("AP6B")
                    }

                    Toggle("已通過值班考核", isOn: $dutyPass)
                }
            }
            .navigationTitle(isEditing ? "編輯成員" : "新增成員")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveMember() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        if let m = member {
            name = m.name
            title = m.title
            sys = m.sys
            skill = m.skill
            grade = m.grade ?? "31"
            plant = m.plant ?? ""
            dutyPass = m.dutyPass
        }
    }

    private func saveMember() {
        title = titleForGrade(grade)
        if var m = member {
            m.name = name
            m.title = title
            m.sys = sys
            m.skill = skill
            m.grade = grade
            m.plant = plant.isEmpty ? nil : plant
            m.dutyPass = dutyPass
            store.updateMember(m)
        } else {
            let m = Member(id: store.newId(), name: name, title: title, sys: sys, skill: skill, grade: grade, plant: plant.isEmpty ? nil : plant, dutyPass: dutyPass)
            store.addMember(m)
        }
        dismiss()
    }
}
