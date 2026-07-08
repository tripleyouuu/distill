import SwiftUI

struct ReferencePhotoOverlay: View {

    let referenceImage: UIImage

    @Binding
    var isVisible: Bool

    let containerSize: CGSize

    @State
    private var dragOffset: CGSize = .zero

    @State
    private var basePosition = CGSize(width: -450, height: -250)

    private let cardWidth: CGFloat = 180

    private var dragBounds: (x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>) {

        let half = (cardWidth + 32) / 2

        return (
            x: (-650)...650,
            y: (-420)...420
        )

    }

    var body: some View {

        if isVisible {
            card
        }

    }

    private var card: some View {

        VStack(spacing: 8) {

            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 2)

            Text("Chosen Moment")
                .font(.caption2.weight(.semibold))

            Image(uiImage: referenceImage)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardWidth)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )

        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 20))
        .offset(
            x: basePosition.width + dragOffset.width,
            y: basePosition.height + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged {
                    dragOffset = $0.translation
                }
                .onEnded { value in

                    basePosition.width = min(
                        max(
                            basePosition.width + value.translation.width,
                            dragBounds.x.lowerBound
                        ),
                        dragBounds.x.upperBound
                    )

                    basePosition.height = min(
                        max(
                            basePosition.height + value.translation.height,
                            dragBounds.y.lowerBound
                        ),
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
            containerSize: CGSize(width: 650, height: 650)
        )

    }

}
