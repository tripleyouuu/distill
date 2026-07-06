import SwiftUI

struct PaletteStripView: View {
    let hexColors: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(hexColors, id: \.self) { hex in
                ColorSwatchView(color: Color(hex: hex))
            }
        }
    }
}

#Preview {
    PaletteStripView(hexColors: ["#FF5733", "#2E86AB", "#A23B72", "#F18F01", "#C73E1D"])
        .padding()
}
