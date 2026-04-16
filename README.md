# 峰哥管家 — 台積人的工作管理神器

專為半導體廠區工程師打造的部門管理 iOS App，整合出勤追蹤、請假管理、會議排程、值班排班四大核心功能。

## 功能總覽

| 頁面 | 功能 |
|------|------|
| 總覽 | 日期選擇、當日會議、當日請假、值班排程一頁掌握 |
| 出勤 | 出勤卡片、統計數據（出勤/請假/病假/出勤率）、月度熱圖 |
| 會議 | 會議 CRUD、時長自動計算、當日會議看板 |
| 請假 | 請假 CRUD、當日請假看板、自動計算結束日期 |
| 成員 | 部門成員管理、職等自動對應職稱、值班考核狀態 |
| 資料 | JSON 匯出/匯入備份、iCloud 同步狀態、重置預設 |

## 值班排班

支援三種班別自動排班：

- **日班** — 單日排班，標準班次 08:30–20:30
- **夜班（6天制）** — 自動產生 6 天值班 + 2 天休假，含平日/假日不同時段
- **小夜班（5天制）** — 自動產生 5 天排班，每天 15:30–23:59

## 職等對照表

| 職等 | 職稱 |
|------|------|
| 31 | 工程師 |
| 32 | 資深工程師 |
| 33 | 主任工程師 |
| 33M | 副理 |
| 34 | 副理 |
| 35 | 經理 |
| 36 | 部經理 |

## 技術規格

- **平台**: iOS 16.0+
- **框架**: SwiftUI
- **儲存**: UserDefaults + iCloud Key-Value Storage
- **資料格式**: JSON (Codable)
- **語言**: Swift 5
- **無外部依賴**: 不使用任何第三方套件

## 專案結構

```
WorkRecord/
├── WorkRecordApp.swift              # App 入口 + 檔案匯入處理
├── ContentView.swift                # 主頁面 + 頂部導覽列
├── Info.plist                       # 註冊 JSON 檔案開啟支援
├── WorkRecord.entitlements          # iCloud Key-Value Storage
├── Models/
│   ├── Member.swift                 # 成員模型 + 職等對照表
│   ├── Leave.swift                  # 請假模型
│   ├── Meeting.swift                # 會議模型
│   ├── Duty.swift                   # 值班模型 (日班/夜班/小夜班)
│   └── AttendanceStatus.swift       # 出勤狀態 + 顏色對映
├── ViewModels/
│   └── DataStore.swift              # 資料持久化 + CRUD + iCloud 同步 + 匯入匯出
├── Views/
│   ├── OverviewView.swift           # 總覽頁
│   ├── AttendanceView.swift         # 出勤頁 + 熱圖
│   ├── MeetingsView.swift           # 會議頁
│   ├── LeavesView.swift             # 請假頁
│   ├── MembersView.swift            # 成員頁
│   ├── DataManagementView.swift     # 資料管理頁
│   ├── DutyFormSheet.swift          # 值班排班表單
│   └── Components/
│       ├── Theme.swift              # 色彩主題
│       ├── DateHelper.swift         # 日期工具 + 排班計算
│       ├── SharedComponents.swift   # 通用 UI 組件
│       └── DatePickerCard.swift     # 日期選擇器 + 迷你月曆
└── Assets.xcassets/                 # App Icon + 主題色
```

## iCloud 同步

App 使用 `NSUbiquitousKeyValueStore` 實現跨裝置同步：

- 每次資料異動同時寫入本機 + iCloud
- 其他裝置收到通知後自動拉取最新資料
- 以時間戳判斷新舊，較新版本優先
- 需在 Xcode 開啟 iCloud > Key-value storage capability

## 檔案匯入

支援從外部 App（訊息、LINE、郵件等）分享 JSON 備份檔直接匯入：

1. 收到 `.json` 備份檔
2. 長按 → 分享 → 選擇「峰哥管家」
3. App 自動開啟並匯入資料

## 建置與執行

1. 用 Xcode 15+ 開啟 `WorkRecord.xcodeproj`
2. Target > Signing & Capabilities > 設定你的 Team
3. 加入 iCloud capability > 勾選 Key-value storage
4. 選擇 iPhone 模擬器或實機
5. Build & Run

## 版本記錄

| 版本 | 說明 |
|------|------|
| 2.1 | 支援從訊息/郵件分享匯入 JSON 檔案 |
| 2.0 | 請假頁當日請假卡片即時更新修正 |
| 1.9 | 請假頁新增當日請假人員卡片 |
| 1.8 | 全頁面日期同步、請假頁加日期選擇器 |
| 1.7 | 出勤頁加日期選擇器 |
| 1.6 | 出勤人數含值班、會議卡片等高 |
| 1.5 | 成員列表排序、職等選單自動帶職稱 |
| 1.0 | 初始版本，完整六大功能頁面 |

## 授權

MIT License
