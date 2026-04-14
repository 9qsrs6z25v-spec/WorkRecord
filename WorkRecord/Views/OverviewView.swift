import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDate = DateHelper.todayDate()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "📋", title: "總覽", subtitle: "APFACD-1-06")

            // Date picker
            DatePickerCard(selectedDate: $selectedDate)
                .environmentObject(store)

            // Today's meetings
            meetingsCard

            // Today's leaves
            leavesCard

            // Duty schedule
            dutyCard
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
    }

    // MARK: - Meetings Card
    private var meetingsCard: some View {
        let ds = DateHelper.dateStr(selectedDate)
        let wd = DateHelper.weekdayLabel(selectedDate)
        let todayMtgs = store.meetings
            .filter { $0.date == ds }
            .sorted { $0.time < $1.time }

        return CardView(
            background: Color.clear,
            borderColor: Color(hex: "b48cdc").opacity(0.3)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("📝 當日會議")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "7c4daa"))
                        .kerning(2)
                    Spacer()
                    Text("\(ds)（\(wd)）")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "a07cc0"))
                }

                if todayMtgs.isEmpty {
                    Text("當日無會議安排")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "b09cc0"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    let rows = stride(from: 0, to: todayMtgs.count, by: 2).map { i in
                        Array(todayMtgs[i..<min(i+2, todayMtgs.count)])
                    }
                    VStack(spacing: 8) {
                        ForEach(rows, id: \.first!.id) { pair in
                            HStack(alignment: .top, spacing: 8) {
                                ForEach(pair) { m in
                                    MeetingMiniCard(meeting: m)
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
                colors: [Color(hex: "f3e8ff"), Color(hex: "fce4ec"), Color(hex: "e8f5e9")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(14)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        )
    }

    // MARK: - Leaves Card
    private var leavesCard: some View {
        let ds = DateHelper.dateStr(selectedDate)
        let wd = DateHelper.weekdayLabel(selectedDate)
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

    // MARK: - Duty Card
    private var dutyCard: some View {
        let ds = DateHelper.dateStr(selectedDate)
        let wd = DateHelper.weekdayLabel(selectedDate)
        let isWE = DateHelper.isWeekend(selectedDate)
        let dayDuties = store.duties
            .filter { $0.date == ds }
            .sorted { d1, d2 in
                if d1.type == "夜班休假" && d2.type != "夜班休假" { return false }
                if d2.type == "夜班休假" && d1.type != "夜班休假" { return true }
                return d1.fab < d2.fab
            }

        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🏭 值班排程")
                        .font(.system(size: 13, weight: .bold))
                        .kerning(0.5)
                    Text("\(ds)（\(wd)）\(isWE ? " 例假日" : "")")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.muted)
                }

                if dayDuties.isEmpty {
                    EmptyStateView(icon: "📋", message: "\(ds) 無值班記錄")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(dayDuties) { d in
                            DutyMiniCard(duty: d)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Mini Cards
struct MeetingMiniCard: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(meeting.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "4a2d70"))
                .lineLimit(2)
            if !meeting.time.isEmpty {
                Text("⏰ \(meeting.time)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "7c4daa"))
            }
            if !meeting.place.isEmpty {
                Text("📍 \(meeting.place)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer(minLength: 0)
            if !meeting.note.isEmpty {
                Text(meeting.note)
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "b48cdc").opacity(0.25), lineWidth: 1))
    }
}

struct LeaveMiniCard: View {
    let member: Member
    let status: AttendanceStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(member.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "4a3000"))
            Text("🏷️ \(status.label)")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "a07020"))
            Spacer(minLength: 0)
            if !status.reason.isEmpty {
                Text(status.reason)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "d29922").opacity(0.25), lineWidth: 1))
    }
}

struct DutyMiniCard: View {
    let duty: Duty

    var body: some View {
        let isNightRest = duty.type == "夜班休假"
        let isNight = duty.type == "夜班" || duty.shift.contains("夜班")
        let isEve = duty.type == "小夜班"
        let fabColor = duty.fab == "B" ? Color(hex: "a371f7") : Color(hex: "388bfd")
        let fabBg = duty.fab == "B" ? Color(hex: "a371f7").opacity(0.1) : Color(hex: "388bfd").opacity(0.1)
        let fabBorder = duty.fab == "B" ? Color(hex: "a371f7").opacity(0.3) : Color(hex: "388bfd").opacity(0.3)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(isNightRest ? (duty.fab.isEmpty ? "–" : "\(duty.fab)廠") : (duty.fab == "B" ? "B廠" : "A廠"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isNightRest ? Color(hex: "7b52a8") : fabColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isNightRest ? Color(hex: "5a3c82").opacity(0.12) : fabBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isNightRest ? Color(hex: "5a3c82").opacity(0.2) : fabBorder, lineWidth: 1))

                Text(isNightRest ? "🌘 夜班休假" : "\(isEve ? "🌆" : isNight ? "🌙" : "☀️") \(duty.type)")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.muted)
            }

            Text(duty.person)
                .font(.system(size: 15, weight: .bold))

            Text(isNightRest ? (duty.shift.isEmpty ? "休假中" : duty.shift) : "⏱ \(duty.shift)")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.muted)

            if !duty.backup.isEmpty {
                Text("備援：\(duty.backup)")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.muted)
            }
            if !duty.note.isEmpty {
                Text(duty.note)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "5a5448"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(isNightRest ? Color(hex: "5a3c82").opacity(0.08) : fabBg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isNightRest ? Color(hex: "5a3c82").opacity(0.2) : fabBorder, lineWidth: 1))
        .opacity(isNightRest ? 0.75 : 1)
    }
}
