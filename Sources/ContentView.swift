import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var vm: DetectionViewModel
    @State private var showSettings = false
    @State private var showGalleryPicker = false
    @State private var pickedImage: UIImage? = nil

    var body: some View {
        ZStack {
            // ✅ 有圖就顯示圖片；否則顯示相機
            if let img = pickedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                CameraView(session: vm.camera.session)
                    .ignoresSafeArea()
            }

            BoxOverlay(predictions: vm.predictions)
                .environmentObject(vm)

            VStack(spacing: 0) {
                TopBar(
                    fpsText: String(format: "FPS %.1f", vm.fps),
                    items: Array(vm.summary.prefix(6)),
                    onSettings: { showSettings.toggle() }
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 10) {
                    BottomControls(
                        isLive: $vm.isLive,
                        onClear: {
                            vm.predictions = []
                            vm.summary = []
                        },
                        onUpload: { showGalleryPicker = true }
                    )

                    VStack(spacing: 6) {
                        Text("Confidence ≥ \(Int(vm.confidenceThreshold * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $vm.confidenceThreshold, in: 0...1, step: 0.01)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
                .padding(.horizontal)
                .background(.ultraThinMaterial)
            }
        }
        // ✅ 選到圖片後：停相機、切非 Live、跑單張推論
        .onChange(of: pickedImage) { img in
            guard let img else { return }
            vm.stop()
            vm.isLive = false
            vm.runOnImage(img)
        }
        // ✅ 切回 Live：清圖片並啟動相機；Pause：停止相機
        .onChange(of: vm.isLive) { on in
            if on {
                pickedImage = nil
                vm.start()
            } else {
                vm.stop()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(vm)
        }
        .sheet(isPresented: $showGalleryPicker) {
            ImagePicker(image: $pickedImage)   // 選圖後會觸發上面的 onChange
        }
        .task {
            await vm.camera.configure()
            await vm.loadModel()
            vm.start()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DetectionViewModel()
        vm.isLive = false
        vm.frameSize = CGSize(width: 1080, height: 1920)
        vm.summary = [
            DetectionSummary(label: "other", confidence: 0.92),
            DetectionSummary(label: "kingston", confidence: 0.81)
        ]
        vm.predictions = [
            Prediction(rect: CGRect(x: 0.15, y: 0.55, width: 0.35, height: 0.25),
                       label: "other", confidence: 0.92, color: .green),
            Prediction(rect: CGRect(x: 0.50, y: 0.25, width: 0.30, height: 0.22),
                       label: "kingston", confidence: 0.85, color: .red)
        ]
        return ContentView().environmentObject(vm)
    }
}





private struct TopBar: View {
    let fpsText: String
    let items: [DetectionSummary]
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Label(fpsText, systemImage: "gauge.with.dots.needle.bottom.50percent")
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            if !items.isEmpty {
                DetectionPanel(items: items)
            }

            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }
}

private struct BottomControls: View {
    @Binding var isLive: Bool
    var onClear: () -> Void
    var onUpload: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClear) {
                Text("Clear")
            }
            .buttonStyle(.bordered)

            Button(action: onUpload) {
                Text("Upload")
            }
            .buttonStyle(.bordered)

            Toggle(isOn: $isLive) {
                Text(isLive ? "Pause" : "Live")
            }
            .toggleStyle(.button)
        }
    }
}

private struct DetectionPanel: View {
    let items: [DetectionSummary]

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Detections")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
            ForEach(items) { s in
                HStack(spacing: 8) {
                    Text(s.label).lineLimit(1)
                    Text("\(Int(s.confidence * 100))%").opacity(0.8)
                }
                .font(.caption2)
                .foregroundStyle(.white)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


