import SwiftUI

enum AppTab: String, CaseIterable {
    case overview = "總覽"
    case attendance = "出勤"
    case meetings = "會議"
    case leaves = "請假"
    case members = "成員"
    case data = "資料"

    var icon: String {
        switch self {
        case .overview: return "clipboard"
        case .attendance: return "person.2"
        case .meetings: return "note.text"
        case .leaves: return "sun.max"
        case .attendance: return "person.2"
        case .members: return "person.crop.rectangle"
        case .data: return "externaldrive"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedTab: AppTab = .overview

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            TopBarView(selectedTab: $selectedTab)

            // Page content
            TabContent(selectedTab: selectedTab)
                .environmentObject(store)
        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct TopBarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Color(hex: "16213e").frame(height: UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?.safeAreaInsets.top ?? 44)

            HStack(spacing: 0) {
                // Logo
                Text("峰哥管家")
                    .font(.custom("", size: 14))
                    .fontWeight(.black)
                    .foregroundColor(Color(hex: "e2b04a"))
                    .kerning(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Nav tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(AppTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                VStack(spacing: 4) {
                                    Text(tabLabel(tab))
                                        .font(.system(size: 11))
                                        .foregroundColor(selectedTab == tab ? Color(hex: "e2b04a") : Color.white.opacity(0.5))
                                    Rectangle()
                                        .fill(selectedTab == tab ? Color(hex: "e2b04a") : Color.clear)
                                        .frame(height: 2)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                }

                Spacer()

                // Sync dot
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: .green, radius: 3)
                    .padding(.trailing, 12)
            }
            .background(Color(hex: "16213e"))
        }
        .background(Color(hex: "16213e"))
    }

    func tabLabel(_ tab: AppTab) -> String {
        switch tab {
        case .overview: return "📋 總覽"
        case .attendance: return "👥 出勤"
        case .meetings: return "📝 會議"
        case .leaves: return "🏖️ 請假"
        case .members: return "🧑‍💼 成員"
        case .data: return "💾 資料"
        }
    }
}

struct TabContent: View {
    let selectedTab: AppTab
    @EnvironmentObject var store: DataStore

    var body: some View {
        ScrollView {
            switch selectedTab {
            case .overview:
                OverviewView()
            case .attendance:
                AttendanceView()
            case .meetings:
                MeetingsView()
            case .leaves:
                LeavesView()
            case .members:
                MembersView()
            case .data:
                DataManagementView()
            }
        }
        .background(Color(hex: "ede8de"))
    }
}
