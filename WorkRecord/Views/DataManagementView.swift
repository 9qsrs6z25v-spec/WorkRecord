import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @EnvironmentObject var store: DataStore
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var showResetAlert = false
    @State private var importResult = ""
    @State private var importSuccess = false
    @State private var toastMessage = ""
    @State private var showToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(icon: "💾", title: "資料管理")

            // iCloud sync status
            iCloudCard

            // Export
            exportCard

            // Import
            importCard

            // Reset
            resetCard
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
        .sheet(isPresented: $showExportSheet) {
            if let data = store.exportJSON() {
                let dateStr = DateHelper.dateStr(Date())
                ShareSheet(items: [
                    JSONFileItem(data: data, fileName: "峰哥管家備份_\(dateStr).json")
                ])
            }
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker(onPick: importFile)
        }
    }

    // MARK: - iCloud Card
    private var iCloudCard: some View {
        CardView(borderColor: store.iCloudEnabled ? AppTheme.sage.opacity(0.3) : AppTheme.border) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("iCloud 同步")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.iCloudEnabled ? AppTheme.sage : AppTheme.muted)
                            .frame(width: 8, height: 8)
                        Text(store.iCloudEnabled ? "已啟用" : "未啟用")
                            .font(.system(size: 11))
                            .foregroundColor(store.iCloudEnabled ? AppTheme.sage : AppTheme.muted)
                    }
                }

                if store.iCloudEnabled {
                    Text("資料會自動透過 iCloud 同步到你所有登入相同 Apple ID 的裝置。每次新增、編輯、刪除都會即時同步。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.muted)

                    if let syncTime = store.lastSyncTime {
                        let formatter: DateFormatter = {
                            let f = DateFormatter()
                            f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            return f
                        }()
                        HStack {
                            Text("最後同步")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.muted)
                            Text(formatter.string(from: syncTime))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.sage)
                        }
                    }
                } else {
                    Text("iCloud 未登入或未啟用。請到「設定 > Apple ID > iCloud」確認已開啟，即可自動跨裝置同步資料。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.muted)
                }
            }
        }
    }

    // MARK: - Export Card
    private var exportCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("📤 匯出資料")
                    .font(.system(size: 13, weight: .bold))

                Text("將所有資料（成員、請假、會議、值班）匯出為 JSON 檔案，可用於備份或換裝置使用。手機上會開啟分享選單。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.muted)

                PrimaryButton(title: "📤 分享 / 下載備份") {
                    showExportSheet = true
                }
            }
        }
    }

    // MARK: - Import Card
    private var importCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("📥 匯入資料")
                    .font(.system(size: 13, weight: .bold))

                Text("選擇先前匯出的 JSON 備份檔，覆蓋目前所有資料（無法復原，請先備份）。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.muted)

                Button(action: { showImportPicker = true }) {
                    Text("📂 點擊選擇 JSON 檔案")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AppTheme.paper)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.border, style: StrokeStyle(lineWidth: 2, dash: [6]))
                        )
                }

                if !importResult.isEmpty {
                    Text(importResult)
                        .font(.system(size: 12))
                        .foregroundColor(importSuccess ? AppTheme.sage : AppTheme.rust)
                        .padding(8)
                        .background((importSuccess ? AppTheme.sage : AppTheme.rust).opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Reset Card
    private var resetCard: some View {
        CardView(borderColor: AppTheme.rust.opacity(0.3)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("⚠️ 重置為預設資料")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.rust)

                Text("清除所有資料並還原至預設的 12 位成員及範例記錄。建議先匯出備份再執行。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.muted)

                Button(action: { showResetAlert = true }) {
                    Text("🔄 重置所有資料")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.rust)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(AppTheme.rust.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.rust.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .alert("確定重置？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                store.resetToPreset()
            }
        } message: {
            Text("確定要重置所有資料至預設值？\n（包含部門成員、請假記錄、會議記錄）")
        }
    }

    // MARK: - Import
    private func importFile(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            try store.importJSON(data)
            importResult = "✅ 匯入成功！"
            importSuccess = true
        } catch {
            importResult = "❌ 匯入失敗：\(error.localizedDescription)"
            importSuccess = false
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - JSON File Item for sharing
class JSONFileItem: NSObject, UIActivityItemSource {
    let data: Data
    let fileName: String

    init(data: Data, fileName: String) {
        self.data = data
        self.fileName = fileName
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileName
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tmpURL)
        return tmpURL
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "峰哥管家備份"
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                onPick(url)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
