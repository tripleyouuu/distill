import SwiftUI

struct PaintingCard: View {
    let image: UIImage
    let paletteHex: [String]

    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))

            PaletteStripView(hexColors: paletteHex)
        }
    }
}

#Preview {
    PaintingCard(
        image: UIImage(systemName: "photo")!,
        paletteHex: ["#FF5733", "#2E86AB", "#A23B72", "#F18F01", "#C73E1D"]
    )
    .padding()
}
