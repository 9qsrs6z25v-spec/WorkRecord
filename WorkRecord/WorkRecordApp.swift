import SwiftUI

@main
struct WorkRecordApp: App {
    @StateObject private var store = DataStore()
    @State private var showImportAlert = false
    @State private var importMessage = ""
    @State private var importSuccess = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onOpenURL { url in
                    handleIncomingFile(url)
                }
                .alert(importSuccess ? "匯入成功" : "匯入失敗", isPresented: $showImportAlert) {
                    Button("確定") {}
                } message: {
                    Text(importMessage)
                }
        }
    }

    private func handleIncomingFile(_ url: URL) {
        // Access security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            try store.importJSON(data)
            importMessage = "已成功匯入備份資料！"
            importSuccess = true
        } catch {
            importMessage = "無法匯入：\(error.localizedDescription)"
            importSuccess = false
        }
        showImportAlert = true
    }
}
