import SwiftUI

struct ColorSwatchView: View {
    let color: Color
    var size: CGFloat = 14

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 8) {
        ColorSwatchView(color: Color(hex: "#FF5733"))
        ColorSwatchView(color: Color(hex: "#2E86AB"))
        ColorSwatchView(color: Color(hex: "#A23B72"))
        ColorSwatchView(color: Color(hex: "#F18F01"))
        ColorSwatchView(color: Color(hex: "#C73E1D"))
    }
    .padding()
}
