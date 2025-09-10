import SwiftUI
import Vision

struct BoxOverlay: View {
    let predictions: [Prediction]
    @EnvironmentObject var vm: DetectionViewModel   // 需要 vm.frameSize

    var body: some View {
        GeometryReader { geo in
            let viewW = geo.size.width
            let viewH = geo.size.height
            let imgW  = max(vm.frameSize.width, 1)
            let imgH  = max(vm.frameSize.height, 1)

            // Aspect Fill 計算：把原圖放大到充滿 view
            let scale = max(viewW / imgW, viewH / imgH)
            let dispW = imgW * scale
            let dispH = imgH * scale
            let offX  = (viewW - dispW) / 2
            let offY  = (viewH - dispH) / 2

            ForEach(predictions) { p in
                // Vision 的 normalized 是左下為原點；先翻 Y 再轉像素
                let nx = p.rect.minX
                let ny = p.rect.minY
                let nw = p.rect.width
                let nh = p.rect.height

                let ix = nx * imgW
                let iy = (1.0 - ny - nh) * imgH
                let iw = nw * imgW
                let ih = nh * imgH

                // 套用 Aspect Fill 的縮放與偏移
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
