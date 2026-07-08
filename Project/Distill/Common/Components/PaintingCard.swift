import SwiftUI

struct PaintingCard: View {
    let image: UIImage
    let paletteHex: [String]

    // These default to false so existing call sites that don't pass them still compile.
    var isSelecting: Bool = false
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
                // Border around the painting image (blue when selected, primary when not).
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(isSelected ? Color.blue : Color.primary, lineWidth: isSelected ? 3 : 2)
                }
                // Circle indicator in the top-right corner.
                // Empty ring = in selection mode but not yet picked.
                // Filled checkmark = picked.
                .overlay(alignment: .topTrailing) {
                    if isSelecting {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? .blue : .white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                            .padding(6)
                    }
                }

            PaletteStripView(hexColors: paletteHex)
        }
    }
}

#Preview {
    HStack {
        // Normal
        PaintingCard(
            image: UIImage(systemName: "photo")!,
            paletteHex: ["#FF5733", "#2E86AB", "#A23B72"]
        )
        // In selection mode, not selected
        PaintingCard(
            image: UIImage(systemName: "photo")!,
            paletteHex: ["#FF5733", "#2E86AB", "#A23B72"],
            isSelecting: true,
            isSelected: false
        )
        // In selection mode, selected
        PaintingCard(
            image: UIImage(systemName: "photo")!,
            paletteHex: ["#FF5733", "#2E86AB", "#A23B72"],
            isSelecting: true,
            isSelected: true
        )
    }
    .padding()
}
