import SwiftUI

struct DutyFormSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var mode: DutyMode = .day
    // Day shift fields
    @State private var date = DateHelper.today()
    @State private var dutyType = "平日值班"
    @State private var person = ""
    @State private var backup = ""
    @State private var note = ""
    // Night shift fields
    @State private var nightStart = DateHelper.today()
    @State private var nightPerson = ""
    @State private var nightBackup = ""
    @State private var nightNote = ""
    // Eve shift fields
    @State private var eveStart = DateHelper.today()
    @State private var evePerson = ""
    @State private var eveBackup = ""
    @State private var eveNote = ""

    private var passedMembers: [Member] {
        store.members.filter { $0.dutyPass }
    }

    private var allMembers: [Member] {
        store.members
    }

    private func fabForPerson(_ name: String) -> String {
        guard let m = store.members.first(where: { $0.name == name }) else { return "A" }
        return m.plant == "AP6B" ? "B" : "A"
    }

    var body: some View {
        NavigationView {
            Form {
                // Mode selector
                Section(header: Text("班別")) {
                    Picker("班別", selection: $mode) {
                        ForEach(DutyMode.allCases, id: \.self) { m in
                            Text(m.label).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch mode {
                case .day:
                    dayForm
                case .night:
                    nightForm
                case .eve:
                    eveForm
                }
            }
            .navigationTitle("新增值班")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveDuty() }
                }
            }
        }
    }

    // MARK: - Day Form
    private var dayForm: some View {
        Group {
            Section(header: Text("值班資訊")) {
                DatePicker("日期", selection: Binding(
                    get: { DateHelper.parseDate(date) ?? Date() },
                    set: { date = DateHelper.dateStr($0) }
                ), displayedComponents: .date)

                Picker("值班類型", selection: $dutyType) {
                    ForEach(dutyTypeOptions, id: \.self) { Text($0) }
                }

                Picker("值班人員", selection: $person) {
                    Text("選擇人員").tag("")
                    ForEach(passedMembers) { m in
                        Text(m.name).tag(m.name)
                    }
                }

                if !person.isEmpty {
                    HStack {
                        Text("廠別")
                        Spacer()
                        Text(fabForPerson(person) == "B" ? "B廠（AP6B）" : "A廠（AP6A）")
                            .foregroundColor(AppTheme.muted)
                    }
                }

                Picker("備援（選填）", selection: $backup) {
                    Text("無").tag("")
                    ForEach(allMembers) { m in
                        Text(m.name).tag(m.name)
                    }
                }

                TextField("備註", text: $note)
            }
        }
    }

    // MARK: - Night Form
    private var nightForm: some View {
        Group {
            Section(header: Text("夜班排班（6天值班 + 2天休假）")) {
                DatePicker("起始日", selection: Binding(
                    get: { DateHelper.parseDate(nightStart) ?? Date() },
                    set: { nightStart = DateHelper.dateStr($0) }
                ), displayedComponents: .date)

                Picker("值班人員", selection: $nightPerson) {
                    Text("選擇人員").tag("")
                    ForEach(passedMembers) { m in
                        Text(m.name).tag(m.name)
                    }
                }

                if !nightPerson.isEmpty {
                    HStack {
                        Text("廠別")
                        Spacer()
                        Text(fabForPerson(nightPerson) == "B" ? "B廠（AP6B）" : "A廠（AP6A）")
                            .foregroundColor(AppTheme.muted)
                    }
                }

                Picker("備援（選填）", selection: $nightBackup) {
                    Text("無").tag("")
                    ForEach(allMembers) { m in
                        Text(m.name).tag(m.name)
                    }
                }

                TextField("備註", text: $nightNote)
            }

            Section(header: Text("排班預覽")) {
                let schedule = DateHelper.calcNightSchedule(startDate: nightStart)
                ForEach(Array(schedule.enumerated()), id: \.offset) { _, record in
                    HStack {
                        Text("\(record.date)（\(DateHelper.weekdayLabel(record.date))）")
                            .font(.system(size: 10))
                            .foregroundColor(DateHelper.isWeekend(record.date) ? AppTheme.sick : AppTheme.muted)
                            .frame(width: 110, alignment: .leading)
                        Text(record.isRest ? "🌙" : "🔵")
                        Text(record.shift)
                            .font(.system(size: 11))
                            .foregroundColor(record.isRest ? AppTheme.muted : AppTheme.training)
                    }
                }
            }
        }
    }

    // MARK: - Eve Form
    private var eveForm: some View {
        Group {
            Section(header: Text("小夜班排班（5天）")) {
                DatePicker("起始日", selection: Binding(
                    get: { DateHelper.parseDate(eveStart) ?? Date() },
                    set: { eveStart = DateHelper.dateStr($0) }
                ), displayedComponents: .date)

                Picker("值班人員", selection: $evePerson) {
                    Text("選擇人員").tag("")
                    ForEach(passedMembers) { m in
                        Text(m.name).tag(m.name)
                    }
                }

                if !evePerson.isEmpty {
                    HStack {
                        Text("廠別")
                        Spacer()
                        Text(fabForPerson(evePerson) == "B" ? "B廠（AP6B）" : "A廠（AP6A）")
                            .foregroundColor(AppTheme.muted)
                    }
                }

                Picker("備援（選填）", selection: $eveBackup) {
                    Text("無").tag("")
                    ForEach(allMembers) { m in
                        Text(m.name).tag(m.name)
                    }
                }

                TextField("備註", text: $eveNote)
            }

            Section(header: Text("排班預覽")) {
                let schedule = DateHelper.calcEveSchedule(startDate: eveStart)
                ForEach(Array(schedule.enumerated()), id: \.offset) { _, record in
                    HStack {
                        Text("\(record.date)（\(DateHelper.weekdayLabel(record.date))）")
                            .font(.system(size: 10))
                            .foregroundColor(DateHelper.isWeekend(record.date) ? AppTheme.sick : AppTheme.muted)
                            .frame(width: 110, alignment: .leading)
                        Text("🌆")
                        Text(record.shift)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "d29922"))
                    }
                }
            }
        }
    }

    // MARK: - Save
    private func saveDuty() {
        switch mode {
        case .day:
            guard !person.isEmpty else { return }
            let fab = fabForPerson(person)
            let duty = Duty(id: store.newId(), date: date, fab: fab, person: person,
                           type: dutyType, shift: "08:30–20:30", backup: backup, note: note)
            store.addDuty(duty)

        case .night:
            guard !nightPerson.isEmpty else { return }
            let fab = fabForPerson(nightPerson)
            let schedule = DateHelper.calcNightSchedule(startDate: nightStart)

            var newDuties: [Duty] = []
            for record in schedule {
                if record.isRest {
                    newDuties.append(Duty(id: store.newId(), date: record.date, fab: fab,
                                         person: nightPerson, type: "夜班休假",
                                         shift: record.shift, backup: "", note: nightNote.isEmpty ? record.shift : nightNote,
                                         nightGroup: nightStart))
                } else {
                    newDuties.append(Duty(id: store.newId(), date: record.date, fab: fab,
                                         person: nightPerson, type: "夜班",
                                         shift: record.shift, backup: nightBackup, note: nightNote,
                                         nightGroup: nightStart))
                }
            }
            store.addDuties(newDuties)

        case .eve:
            guard !evePerson.isEmpty else { return }
            let fab = fabForPerson(evePerson)
            let schedule = DateHelper.calcEveSchedule(startDate: eveStart)

            var newDuties: [Duty] = []
            for record in schedule {
                newDuties.append(Duty(id: store.newId(), date: record.date, fab: fab,
                                     person: evePerson, type: "小夜班",
                                     shift: record.shift, backup: eveBackup, note: eveNote,
                                     eveGroup: eveStart))
            }
            store.addDuties(newDuties)
        }
        dismiss()
    }
}
