# Kingston Detector – YOLOv8 iOS App

這是一個基於 [YOLOv8](https://github.com/ultralytics/ultralytics) 物件偵測模型的 iOS App，支援即時相機推論與圖片上傳偵測。專案使用 **CoreML** 部署，並以 **SwiftUI + Vision + AVFoundation** 建立使用者介面。

## 📱 Demo
👉 [Kingston Detector Demo 影片](https://youtube.com/shorts/ICmD30B0Lec?feature=share)



## ✨ 功能特點
- 📸 **即時相機偵測**：透過 iPhone 相機串流進行即時物件偵測  
- 🖼️ **圖片上傳**：可從相簿選取圖片進行離線推論 (to-do)
- 🎛️ **信心閾值滑桿**：動態調整模型的信心閾值  
- 📊 **偵測摘要清單**：畫面右上角顯示前 6 個偵測結果  
- 🎨 **自訂框顏色**：特定標籤（如 `Kingston`）會顯示紅色框  
- 💾 **快照存檔**：可將推論結果（含偵測框）存到相簿 (to-do)

## 🛠️ 專案架構
```
YOLOv8-iOS-full-2/
├── iOSApp/
│   ├── Sources/
│   │   ├── ContentView.swift       # 主畫面
│   │   ├── DetectionViewModel.swift# 模型與相機處理
│   │   ├── Camera.swift            # 相機管理
│   │   ├── Overlay.swift           # 偵測框繪製
│   │   ├── SettingsView.swift      # 設定頁
│   │   └── Models.swift            # Prediction & DetectionSummary
│   └── Resources/
│       ├── Models/YOLOv8.mlmodelc  # CoreML 模型
│       └── labels.txt              # 類別名稱
└── README.md
```

## 🚀 安裝與執行
1. 確保已安裝 **Xcode 15+**（支援 iOS 17/18 SDK）  
2. 下載或 clone 專案：
   ```bash
   git clone https://github.com/HuiHsin-Cheng/Kingston-Detector-Yolov8.git
   cd Kingston-Detector-Yolov8
   ```
3. 打開 `YOLOv8Demo.xcodeproj` 或 `YOLOv8Demo.xcworkspace`  
4. 在 Xcode 選擇你的 iPhone 裝置並 **Run (⌘R)**  

## 📦 模型轉換
1. 將 YOLOv8 `.pt` 權重轉成 CoreML：
   ```bash
   yolo export model=best.pt format=coreml
   ```
2. 把輸出的 `.mlmodel` 或 `.mlpackage` 放到 `iOSApp/Resources/Models/`  
3. 確認 `labels.txt` 與模型對應的類別順序一致  

## 📝 待辦
- [ ] 支援錄影推論與導出影片  
- [ ] 改善效能：Metal Delegate / CoreML GPU 優化  
- [ ] 多模型切換 UI  

## 📄 授權
本專案採用 MIT License，詳見 [LICENSE](LICENSE)。

---
Made with ❤️ by Hui-Hsin Cheng
