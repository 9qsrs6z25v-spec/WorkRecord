import SwiftUI

struct AttendanceView: View {
    @EnvironmentObject var store: DataStore
    @State private var showDutyForm = false
    @State private var showFieldMenu = false
    @State private var fieldTitle = true
    @State private var fieldSys = false
    @State private var fieldSkill = false
    @State private var fieldGrade = false
    @State private var fieldPlant = false
    @State private var fieldReason = true

    private var ds: String { DateHelper.dateStr(store.selectedDate) }
    private var isHol: Bool { DateHelper.isWeekend(store.selectedDate) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "👥", title: "人員出勤狀態",
                         subtitle: "\(ds)（\(DateHelper.weekdayLabel(store.selectedDate))）")

            statsGrid
            attendanceCards
            heatmapCard
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
        .sheet(isPresented: $showDutyForm) {
            DutyFormSheet()
                .environmentObject(store)
        }
    }

    // MARK: - Stats
    private var stats: (present: Int, leave: Int, sick: Int, rate: Int) {
        var present = 0, leave = 0, sick = 0, duty = 0
        let dutyOnDay = store.duties.filter { $0.date == ds && $0.type != "夜班休假" }

        if isHol && dutyOnDay.isEmpty {
            return (0, 0, 0, 0)
        }

        for m in store.members {
            let s = store.getStatus(name: m.name, dateStr: ds)
            switch s.code {
            case "duty": duty += 1
            case "present": present += 1
            case "sick": sick += 1
            case "training": leave += 1
            case "holiday": break
            case "night-rest": leave += 1
            default: leave += 1
            }
        }

        let total = store.members.count
        // 平日：出勤 = present + duty（值班也是出勤）
        // 假日：出勤 = duty
        let activeCount = isHol ? duty : (present + duty)
        let leaveCount = isHol ? (total - duty) : leave
        let rate = total > 0 ? Int(round(Double(activeCount) / Double(total) * 100)) : 0

        return (activeCount, leaveCount, isHol ? 0 : sick, rate)
    }

    private var statsGrid: some View {
        let s = stats
        let rateColor: Color = s.rate >= 90 ? AppTheme.present : (s.rate >= 75 ? AppTheme.leave : AppTheme.sick)

        return HStack(spacing: 10) {
            StatBox(label: isHol ? "值班" : "出勤", value: "\(s.present)", unit: "人",
                    color: AppTheme.present,
                    bgColor: AppTheme.present.opacity(0.08),
                    borderColor: AppTheme.present.opacity(0.2))
            StatBox(label: isHol ? "休假" : "請假", value: isHol && s.leave == 0 ? "—" : "\(s.leave)", unit: "人",
                    color: AppTheme.leave,
                    bgColor: AppTheme.leave.opacity(0.08),
                    borderColor: AppTheme.leave.opacity(0.2))
            StatBox(label: "病假", value: isHol ? "—" : "\(s.sick)", unit: "人",
                    color: AppTheme.sick,
                    bgColor: AppTheme.sick.opacity(0.08),
                    borderColor: AppTheme.sick.opacity(0.2))
            StatBox(label: isHol ? "值班率" : "出勤率", value: s.rate > 0 ? "\(s.rate)" : "—", unit: "%",
                    color: rateColor,
                    bgColor: AppTheme.training.opacity(0.08),
                    borderColor: AppTheme.training.opacity(0.2))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - Attendance Cards
    private var attendanceCards: some View {
        let dutyOnDay = store.duties.filter { $0.date == ds && $0.type != "夜班休假" }

        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("出勤卡片")
                        .font(.system(size: 13, weight: .bold))
                        .kerning(0.5)
                    Spacer()
                    Button("＋ 新增值班") { showDutyForm = true }
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.blue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                }

                if isHol && dutyOnDay.isEmpty {
                    Text("🌙  \(ds) 為例假日，無值班記錄")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                } else {
                    let columns = [GridItem(.adaptive(minimum: 130), spacing: 9)]
                    LazyVGrid(columns: columns, spacing: 9) {
                        ForEach(store.members) { m in
                            let s = store.getStatus(name: m.name, dateStr: ds)
                            if s.code != "holiday" {
                                AttendanceCard(member: m, status: s,
                                               showTitle: fieldTitle, showSys: fieldSys,
                                               showSkill: fieldSkill, showGrade: fieldGrade,
                                               showPlant: fieldPlant, showReason: fieldReason)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Heatmap
    private var heatmapCard: some View {
        let y = Calendar.current.component(.year, from: store.selectedDate)
        let m = Calendar.current.component(.month, from: store.selectedDate) - 1

        return CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("🗓️ 本月出勤熱圖")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("\(String(y))年\(DateHelper.months[m])")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.muted)
                }

                ScrollView(.horizontal, showsIndicators: true) {
                    HeatmapGrid(year: y, month: m)
                        .environmentObject(store)
                }

                heatmapLegend
            }
        }
    }

    private var heatmapLegend: some View {
        let items: [(String, Color)] = [
            ("出勤", Color(hex: "3fb950").opacity(0.7)),
            ("訓練/公假", Color(hex: "388bfd").opacity(0.7)),
            ("事假/特休", Color(hex: "a371f7").opacity(0.7)),
            ("病假", Color(hex: "f85149").opacity(0.7)),
            ("假日值班", Color(hex: "ea8a28").opacity(0.85)),
            ("小夜班", Color(hex: "d29922").opacity(0.85)),
            ("夜班", Color(hex: "3c1478").opacity(0.75)),
            ("夜班休假", Color(hex: "5a3c82").opacity(0.4)),
            ("假日", Color(hex: "30363d").opacity(0.35)),
        ]

        return FlowLayout(spacing: 12) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.1)
                        .frame(width: 10, height: 10)
                    Text(item.0)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.muted)
                }
            }
        }
    }
}

// MARK: - Attendance Card
struct AttendanceCard: View {
    let member: Member
    let status: AttendanceStatus
    var showTitle: Bool = true
    var showSys: Bool = false
    var showSkill: Bool = false
    var showGrade: Bool = false
    var showPlant: Bool = false
    var showReason: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(member.name)
                .font(.system(size: 13, weight: .bold))

            if showTitle {
                Text(member.title)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.muted)
            }
            if showSys && !member.sys.isEmpty {
                Text(member.sys)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.muted)
            }
            if showSkill && !member.skill.isEmpty {
                Text(member.skill)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.blue)
            }
            if showGrade, let g = member.grade {
                Text("職等 \(g)")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.muted)
            }
            if showPlant, let p = member.plant, !p.isEmpty {
                Text(p)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.purple)
            }

            Spacer(minLength: 0)

            statusBadge

            if showReason && !status.reason.isEmpty {
                Text(status.reason)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(11)
        .background(AppTheme.paper)
        .cornerRadius(10)
        .overlay(
            Rectangle()
                .fill(leftBorderColor)
                .frame(width: 3)
                .cornerRadius(3, corners: [.topLeft, .bottomLeft]),
            alignment: .leading
        )
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
    }

    private var leftBorderColor: Color {
        switch status.code {
        case "present": return AppTheme.present
        case "sick": return AppTheme.sick
        case "leave", "personal": return AppTheme.personal
        case "training": return AppTheme.training
        case "duty": return status.fab == "A" ? AppTheme.training : AppTheme.personal
        default: return AppTheme.muted
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Text("\(status.statusIcon) \(status.statusText)")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(status.statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(status.statusColor.opacity(0.12))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(status.statusColor.opacity(0.25), lineWidth: 1))
        .padding(.top, 3)
    }
}

// MARK: - Heatmap Grid
struct HeatmapGrid: View {
    @EnvironmentObject var store: DataStore
    let year: Int
    let month: Int

    var body: some View {
        let dim = DateHelper.daysInMonth(year: year, month: month)
        let todayStr = DateHelper.today()

        let groups: [(key: String, label: String, color: Color, border: Color)] = [
            ("AP6A", "AP6A", Color(hex: "388bfd").opacity(0.15), Color(hex: "388bfd").opacity(0.4)),
            ("AP6B", "AP6B", Color(hex: "a371f7").opacity(0.15), Color(hex: "a371f7").opacity(0.4)),
            ("", "未指定", Color.gray.opacity(0.08), Color.gray.opacity(0.2)),
        ]

        VStack(alignment: .leading, spacing: 2) {
            // Header row
            HStack(spacing: 2) {
                Text("姓名")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.muted)
                    .frame(width: 60, alignment: .leading)
                ForEach(1...dim, id: \.self) { d in
                    let ds = String(format: "%d-%02d-%02d", year, month + 1, d)
                    Text("\(d)")
                        .font(.system(size: 9, weight: ds == todayStr ? .bold : .regular))
                        .foregroundColor(ds == todayStr ? AppTheme.gold : AppTheme.muted)
                        .frame(width: 16, height: 18)
                }
            }

            ForEach(groups, id: \.key) { group in
                let members = store.members.filter { ($0.plant ?? "") == group.key }
                if !members.isEmpty {
                    // Group header
                    HStack(spacing: 4) {
                        Text("🏭 \(group.label)")
                            .font(.system(size: 10, weight: .bold))
                        Text("（\(members.count)人）")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.muted)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(group.color)
                    .cornerRadius(4)
                    .overlay(
                        Rectangle().fill(group.border).frame(width: 3),
                        alignment: .leading
                    )
                    .padding(.top, 6)

                    // Member rows
                    ForEach(members) { mem in
                        HStack(spacing: 2) {
                            Text(mem.name)
                                .font(.system(size: 10))
                                .frame(width: 60, alignment: .leading)
                                .lineLimit(1)
                            ForEach(1...dim, id: \.self) { d in
                                let ds = String(format: "%d-%02d-%02d", year, month + 1, d)
                                let s = store.getStatus(name: mem.name, dateStr: ds)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(s.heatmapColor)
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500)
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
