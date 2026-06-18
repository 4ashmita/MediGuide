import SwiftUI

enum PhotoContext {
    case rash, wound, burn, swelling, general

    var guidanceText: String {
        switch self {
        case .rash:     return "Include the edges of the rash in the frame"
        case .wound:    return "Show the full wound and some surrounding skin"
        case .burn:     return "Include the entire burned area"
        case .swelling: return "Photograph next to an unaffected area for comparison"
        case .general:  return "Fill the frame with the affected area"
        }
    }
}

struct PhotoGuidanceView: View {
    let context: PhotoContext

    var body: some View {
        ZStack {
            framingGuide
            VStack {
                Spacer()
                guidancePill
                    .padding(.bottom, 128)
            }
        }
    }

    // MARK: - Sub-views

    private var framingGuide: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.7
            let rect = CGRect(
                x: (geo.size.width - side) / 2,
                y: (geo.size.height - side) / 2,
                width: side,
                height: side
            )
            ZStack {
                // Dim surround
                Rectangle()
                    .fill(.black.opacity(0.25))
                    .mask(surroundMask(rect: rect, in: geo.size))

                // Corner brackets
                cornerBrackets(rect: rect)
            }
        }
        .ignoresSafeArea()
    }

    private func surroundMask(rect: CGRect, in size: CGSize) -> some View {
        Canvas { context, _ in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            context.blendMode = .destinationOut
            context.fill(RoundedRectangle(cornerRadius: 10).path(in: rect), with: .color(.white))
        }
    }

    private func cornerBrackets(rect: CGRect) -> some View {
        let len: CGFloat = 24
        let lineWidth: CGFloat = 3
        return Canvas { ctx, _ in
            let corners: [(CGPoint, CGPoint, CGPoint)] = [
                // top-left
                (CGPoint(x: rect.minX, y: rect.minY + len),
                 CGPoint(x: rect.minX, y: rect.minY),
                 CGPoint(x: rect.minX + len, y: rect.minY)),
                // top-right
                (CGPoint(x: rect.maxX - len, y: rect.minY),
                 CGPoint(x: rect.maxX, y: rect.minY),
                 CGPoint(x: rect.maxX, y: rect.minY + len)),
                // bottom-left
                (CGPoint(x: rect.minX, y: rect.maxY - len),
                 CGPoint(x: rect.minX, y: rect.maxY),
                 CGPoint(x: rect.minX + len, y: rect.maxY)),
                // bottom-right
                (CGPoint(x: rect.maxX - len, y: rect.maxY),
                 CGPoint(x: rect.maxX, y: rect.maxY),
                 CGPoint(x: rect.maxX, y: rect.maxY - len)),
            ]
            for (a, b, c) in corners {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                path.addLine(to: c)
                ctx.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .ignoresSafeArea()
    }

    private var guidancePill: some View {
        Text(context.guidanceText)
            .font(.subheadline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.horizontal, 32)
    }
}
