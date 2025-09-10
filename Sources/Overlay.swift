import SwiftUI
import Vision

struct BoxOverlay: View {
    let predictions: [Prediction]
    @EnvironmentObject var vm: DetectionViewModel

    var body: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height

            // 依 Vision 的使用方向決定計算用影像寬高（.right / .left 需交換）
            let rawW = max(vm.frameSize.width, 1)
            let rawH = max(vm.frameSize.height, 1)
            let isRotated = (vm.visionOrientation == .right || vm.visionOrientation == .left)
            let imgW: CGFloat = isRotated ? rawH : rawW
            let imgH: CGFloat = isRotated ? rawW : rawH

            // Aspect Fill 映射（等比放大 + 置中裁切）
            let scale = max(viewW / imgW, viewH / imgH)
            let dispW = imgW * scale
            let dispH = imgH * scale
            let offX  = (viewW - dispW) / 2
            let offY  = (viewH - dispH) / 2

            ForEach(predictions) { p in
                // Vision boundingBox: normalized [0,1], 原點在左下
                let nx = p.rect.minX
                let ny = p.rect.minY
                let nw = p.rect.width
                let nh = p.rect.height

                // 轉回像素座標（左上為原點：Y 需翻轉）
                let ix = nx * imgW
                let iy = (1.0 - ny - nh) * imgH
                let iw = nw * imgW
                let ih = nh * imgH

                // 套用等比縮放與偏移 → View 座標
                let vx = ix * scale + offX
                let vy = iy * scale + offY
                let vw = iw * scale
                let vh = ih * scale

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8).stroke(p.color, lineWidth: 2)
                    Text(String(format: "%@ %.0f%%", p.label, p.confidence * 100))
                        .font(.caption).padding(4)
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(4)
                }
                .frame(width: vw, height: vh)
                .position(x: vx + vw/2, y: vy + vh/2)
            }
        }
        .allowsHitTesting(false)
    }
}
