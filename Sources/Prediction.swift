//
//  Prediction.swift
//  YOLOv8Demo
//
//  Created by 鄭惠心 on 2025/9/9.
//
import SwiftUI
import Foundation

struct DetectionSummary: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
}

struct Prediction: Identifiable {
    let id = UUID()
    let rect: CGRect         // 偵測框 (normalized coordinates 0~1)
    let label: String        // 類別名稱
    let confidence: Float    // 信心分數 0~1
    let color: Color         // 顯示顏色 (例如 .green, .red)
}
