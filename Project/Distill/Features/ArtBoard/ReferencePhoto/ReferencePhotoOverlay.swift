import SwiftUI

struct ReferencePhotoOverlay: View {

    let referenceImage: UIImage

    @Binding
    var isVisible: Bool

    let containerSize: CGSize

    @State
    private var dragOffset: CGSize = .zero

    @State
    private var basePosition: CGSize = .init(width: 160, height: -200)

    private let cardWidth: CGFloat = 180

    private var dragBounds: (x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>) {

        let halfCard = (cardWidth + 8) / 2

        return (
            x: (-containerSize.width / 2 + halfCard)...(containerSize.width / 2 - halfCard),
            y: (-containerSize.height / 2 + halfCard + 60)...(containerSize.height / 2 - halfCard - 100)
        )

    }

    var body: some View {

        if isVisible {
            card
        }

    }

    // MARK: - Card

    private var card: some View {

        VStack(spacing: 0) {

            Text("Chosen Moment")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Image(uiImage: referenceImage)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardWidth)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .frame(width: cardWidth + 8)
        .offset(x: dragOffset.width + basePosition.width,
                y: dragOffset.height + basePosition.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    basePosition.width = min(
                        max(basePosition.width + value.translation.width,
                            dragBounds.x.lowerBound),
                        dragBounds.x.upperBound
                    )
                    basePosition.height = min(
                        max(basePosition.height + value.translation.height,
                            dragBounds.y.lowerBound),
                        dragBounds.y.upperBound
                    )
                    dragOffset = .zero
                }
        )

    }

}

#Preview {

    ZStack {

        Color(.systemGray5)
            .ignoresSafeArea()

        ReferencePhotoOverlay(
            referenceImage: UIImage(systemName: "photo")!,
            isVisible: .constant(true),
            containerSize: CGSize(width: 393, height: 852)
        )

    }

}
