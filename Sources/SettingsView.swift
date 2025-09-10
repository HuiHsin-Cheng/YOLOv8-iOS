import SwiftUI
import CoreML

struct SettingsView: View {
    @EnvironmentObject var vm: DetectionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Compute Units") {
                    Picker("Compute", selection: $vm.computeUnit) {
                        Text("All (ANE/GPU/CPU)").tag(MLComputeUnits.all as MLComputeUnits)
                        Text("CPU+GPU").tag(MLComputeUnits.cpuAndGPU as MLComputeUnits)
                        Text("CPU Only").tag(MLComputeUnits.cpuOnly as MLComputeUnits)
                    }
                    .pickerStyle(.inline)
                }

                Section("General") {
                    Toggle("Draw Boxes", isOn: $vm.drawBoxes)
                    Toggle("Live Inference", isOn: $vm.isLive)
                    Stepper(
                        "Confidence ≥ \(String(format: "%.2f", vm.confidenceThreshold))",
                        value: $vm.confidenceThreshold,
                        in: 0.1...0.9,
                        step: 0.05
                    )
                }

                Section("Model") {
                    Button("Reload Model") { Task { await vm.loadModel() } }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
