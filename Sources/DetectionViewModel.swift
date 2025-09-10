import Foundation
import SwiftUI
import AVFoundation
import Vision
import CoreML
import Photos
import UIKit

@MainActor
final class DetectionViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var predictions: [Prediction] = []
    @Published var summary: [DetectionSummary] = []
    @Published var fps: Double = 0
    @Published var isLive: Bool = true { didSet { _isLiveUnsafe = isLive } }
    @Published var drawBoxes: Bool = true
    @Published var confidenceThreshold: Double = 0.25
    @Published var computeUnit: MLComputeUnits = .all
    @Published var frameSize: CGSize = .zero

    let camera = CameraManager()

    private nonisolated(unsafe) var lastTimestamp: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    private nonisolated(unsafe) var req: VNCoreMLRequest?
    private nonisolated(unsafe) var _isLiveUnsafe: Bool = true
    private nonisolated(unsafe) let ciContext = CIContext()
    private nonisolated(unsafe) var lastCGImage: CGImage?

    private var labelMap: [Int: String] = [:]

    func loadModel() async {
        if let labelsURL = Bundle.main.url(forResource: "labels", withExtension: "txt"),
           let text = try? String(contentsOf: labelsURL) {
            var map: [Int: String] = [:]
            for (idx, line) in text.split(separator: "\n").enumerated() {
                map[idx] = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            labelMap = map
        }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = computeUnit
            let url = Bundle.main.url(forResource: "YOLOv8", withExtension: "mlmodelc")
                ?? Bundle.main.url(forResource: "YOLOv8", withExtension: "mlmodel")
                ?? Bundle.main.url(forResource: "YOLOv8", withExtension: "mlpackage")
            guard let modelURL = url else { print("⚠️ model not found"); return }
            let coreml = try MLModel(contentsOf: modelURL, configuration: config)
            let vnModel = try VNCoreMLModel(for: coreml)
            vnModel.inputImageFeatureName = "image"
            let request = VNCoreMLRequest(model: vnModel) { [weak self] request, _ in
                guard let results = request.results else { return }
                self?.handleObservations(results)
            }
            request.imageCropAndScaleOption = .scaleFill
            self.req = request
            camera.delegate = self
        } catch {
            print("Model load error: \(error)")
        }
    }

    func start() {
        #if targetEnvironment(simulator)
        #else
        camera.start()
        #endif
    }

    func stop() { camera.stop() }

    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let selfReq = self.req, _isLiveUnsafe else { return }
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let w = CVPixelBufferGetWidth(pixel)
        let h = CVPixelBufferGetHeight(pixel)
        Task { @MainActor in self.frameSize = CGSize(width: w, height: h) }

        let ci = CIImage(cvPixelBuffer: pixel)
        if let cg = ciContext.createCGImage(ci, from: ci.extent) { self.lastCGImage = cg }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixel, orientation: .right, options: [:])
        do { try handler.perform([selfReq]) } catch { print("VN perform error:", error) }

        let now = CFAbsoluteTimeGetCurrent()
        let dt = now - self.lastTimestamp
        self.lastTimestamp = now
        if dt > 0 { Task { @MainActor in self.fps = min(120, 1.0 / dt) } }
    }

    func runOnImage(_ image: UIImage) {
        guard let cg = image.cgImage, let req else { return }
        Task { @MainActor in self.frameSize = CGSize(width: cg.width, height: cg.height) }
        self.lastCGImage = cg
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .right, options: [:])
        do { try handler.perform([req]) } catch { print("VN perform error:", error) }
    }

    private func handleObservations(_ results: [Any]) {
        var preds: [Prediction] = []
        var sum: [DetectionSummary] = []

        if let observations = results as? [VNRecognizedObjectObservation] {
            for obs in observations where obs.confidence >= Float(confidenceThreshold) {
                let lbl = obs.labels.first?.identifier ?? "obj"
                let color: Color = (lbl.lowercased() == "kingston") ? .red : .green
                preds.append(Prediction(rect: obs.boundingBox,
                                        label: lbl,
                                        confidence: obs.confidence,
                                        color: color))
                sum.append(DetectionSummary(label: lbl, confidence: obs.confidence))
            }
        } else if let mlArray = results as? [VNCoreMLFeatureValueObservation],
                  let f = mlArray.first?.featureValue.multiArrayValue {
            let n = f.shape[0].intValue
            func idx(_ i: Int, _ j: Int) -> Int { i * 6 + j }
            for i in 0..<n {
                let conf = f[idx(i,4)].doubleValue
                if conf < confidenceThreshold { continue }
                let cx = f[idx(i,0)].doubleValue
                let cy = f[idx(i,1)].doubleValue
                let w  = f[idx(i,2)].doubleValue
                let h  = f[idx(i,3)].doubleValue
                let rect = CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h)
                let cls = Int(f[idx(i,5)].doubleValue)
                let name = labelMap[cls] ?? "#\(cls)"
                let color: Color = (name.lowercased() == "kingston") ? .red : .blue
                preds.append(Prediction(rect: rect,
                                        label: name,
                                        confidence: Float(conf),
                                        color: color))
                sum.append(DetectionSummary(label: name, confidence: Float(conf)))
            }
        }

        Task { @MainActor in
            self.predictions = drawBoxes ? preds : []
            self.summary = sum.sorted(by: { $0.confidence > $1.confidence })
        }
    }

    func captureFrameToPhotos() {
        guard let base = self.lastCGImage else { print("No camera frame available"); return }
        let size = CGSize(width: base.width, height: base.height)
        let preds = self.predictions

        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            ctx.cgContext.draw(base, in: CGRect(origin: .zero, size: size))
            for p in preds {
                let r = CGRect(
                    x: CGFloat(p.rect.minX) * size.width,
                    y: CGFloat(p.rect.minY) * size.height,
                    width: CGFloat(p.rect.width) * size.width,
                    height: CGFloat(p.rect.height) * size.height
                )
                ctx.cgContext.setStrokeColor(UIColor.systemGreen.cgColor)
                if p.label.lowercased() == "kingston" {
                    ctx.cgContext.setStrokeColor(UIColor.systemRed.cgColor)
                }
                ctx.cgContext.setLineWidth(3)
                ctx.cgContext.stroke(r)
                let text = "\(p.label) \(Int(p.confidence * 100))%"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: UIColor.white
                ]
                let textSize = (text as NSString).size(withAttributes: attrs)
                let pad: CGFloat = 6
                let labelRect = CGRect(x: r.minX,
                                       y: max(0, r.minY - textSize.height - pad),
                                       width: textSize.width + pad * 2,
                                       height: textSize.height + pad)
                ctx.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
                ctx.cgContext.fill(labelRect)
                (text as NSString).draw(in: labelRect.insetBy(dx: pad, dy: pad / 2), withAttributes: attrs)
            }
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: img)
        }, completionHandler: { success, error in
            print(success ? "Saved snapshot with boxes" : "Save failed: \(String(describing: error))")
        })
    }
}
