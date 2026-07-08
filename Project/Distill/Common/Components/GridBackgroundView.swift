import SwiftUI

struct GridBackgroundView: View {

    var spacing: CGFloat = 10
    var lineColor: Color = Color(hex: "#979797")
    var lineOpacity: Double = 0.18
    var lineWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in

                var path = Path()

                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }

                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }

                context.stroke(
                    path,
                    with: .color(lineColor.opacity(lineOpacity)),
                    lineWidth: lineWidth
                )
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    GridBackgroundView()
}
