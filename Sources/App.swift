import SwiftUI
@main struct YOLOv8DemoApp: App { @StateObject private var detector = DetectionViewModel(); var body: some Scene { WindowGroup { ContentView().environmentObject(detector) } } }