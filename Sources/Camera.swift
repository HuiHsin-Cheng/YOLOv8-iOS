import SwiftUI
import AVFoundation
final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.queue")
    @Published var previewSize: CGSize = .zero
    var videoOutput = AVCaptureVideoDataOutput()
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate? { didSet { videoOutput.setSampleBufferDelegate(delegate, queue: queue) } }
    func configure() async {
        session.beginConfiguration(); session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else { session.commitConfiguration(); return }
        session.addInput(input)
        if session.canAddOutput(videoOutput) { videoOutput.alwaysDiscardsLateVideoFrames = true; videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]; session.addOutput(videoOutput) }
        session.commitConfiguration()
    }
    func start() { if !session.isRunning { session.startRunning() } }
    func stop()  { if  session.isRunning { session.stopRunning() } }
}
struct CameraView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView { let v = PreviewView(); v.session = session; return v }
    func updateUIView(_ uiView: PreviewView, context: Context) { }
}
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var session: AVCaptureSession? { get { previewLayer.session } set { previewLayer.session = newValue } }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    override init(frame: CGRect) { super.init(frame: frame); previewLayer.videoGravity = .resizeAspectFill }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
