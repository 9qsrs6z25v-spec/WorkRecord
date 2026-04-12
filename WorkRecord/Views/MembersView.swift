import SwiftUI

struct MembersView: View {
    @EnvironmentObject var store: DataStore
    @State private var showForm = false
    @State private var editingMember: Member?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "👥", title: "部門成員", subtitle: "（\(store.members.count) 人）")

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("成員列表")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
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

    private var memberTable: some View {
        VStack(spacing: 0) {
            // Header
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("序").frame(width: 25, alignment: .leading)
                        Text("姓名").frame(width: 55, alignment: .leading)
                        Text("職稱").frame(width: 70, alignment: .leading)
                        Text("系統").frame(width: 70, alignment: .leading)
                        Text("技能").frame(width: 90, alignment: .leading)
                        Text("職等").frame(width: 35, alignment: .leading)
                        Text("值班考核").frame(width: 65, alignment: .center)
                        Spacer()
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.muted)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 9)
                    .background(AppTheme.paper)

                    ForEach(Array(store.members.enumerated()), id: \.element.id) { idx, m in
                        MemberTableRow(index: idx + 1, member: m, onEdit: {
                            editingMember = m
                            showForm = true
                        }, onDelete: {
                            store.deleteMember(m.id)
                        })
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

            Text(member.title)
                .font(.system(size: 12))
                .frame(width: 70, alignment: .leading)

            Text(member.sys.isEmpty ? "–" : member.sys)
                .font(.system(size: 12))
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)

            Text(member.skill.isEmpty ? "–" : member.skill)
                .font(.system(size: 12))
                .frame(width: 90, alignment: .leading)
                .lineLimit(1)

            Text(member.grade ?? "–")
                .font(.system(size: 12))
                .frame(width: 35, alignment: .leading)

            HStack {
                if member.dutyPass {
                    BadgeView(text: "✅ 通過", style: BadgeStyle(
                        bg: Color(hex: "e8f5ee"), fg: AppTheme.sage, border: Color(hex: "b5ddc5")))
                } else {
                    BadgeView(text: "— 未通過", style: BadgeStyle(
                        bg: Color(hex: "f5f0e8"), fg: AppTheme.muted, border: AppTheme.border))
                }
            }
            .frame(width: 65, alignment: .center)

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
