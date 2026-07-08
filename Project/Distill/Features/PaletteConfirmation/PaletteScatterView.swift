import SwiftUI

struct PaletteScatterView: View {

    let colors: [Color]
    let imageSize: CGSize

    private let cardSize = CGSize(width: 138, height: 186)

    var body: some View {

        GeometryReader { geometry in

            let displayedImage = fittedImageSize(
                image: imageSize,
                inside: geometry.size
            )

            let transforms = generateTransforms(
                imageSize: displayedImage
            )

            ZStack {

                ForEach(Array(colors.prefix(4).enumerated()), id: \.offset) { index, color in

                    PaletteCardView(
                        color: color,
                        hexCode: color.hex
                    )
                    .rotationEffect(.degrees(transforms[index].rotation))
                    .offset(
                        x: transforms[index].offset.width,
                        y: transforms[index].offset.height
                    )

                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .allowsHitTesting(false)

    }

    private func fittedImageSize(
        image: CGSize,
        inside container: CGSize
    ) -> CGSize {

        guard image.width > 0,
              image.height > 0 else {
            return container
        }

        let imageAspect = image.width / image.height
        let containerAspect = container.width / container.height

        if imageAspect > containerAspect {

            let width = container.width
            let height = width / imageAspect

            return CGSize(width: width, height: height)

        } else {

            let height = container.height
            let width = height * imageAspect

            return CGSize(width: width, height: height)

        }

    }

    private func generateTransforms(
        imageSize: CGSize
    ) -> [CardTransform] {

        let horizontalLimit =
            imageSize.width / 2 - cardSize.width / 2

        let verticalLimit =
            imageSize.height / 2 - cardSize.height / 2

        let isLandscape = imageSize.width > imageSize.height

        let horizontal =
            max(horizontalLimit + (isLandscape ? 0 : 50), 0)

        let vertical =
            max(verticalLimit + (isLandscape ? 50 : 0), 0)
        
        return [

            CardTransform(
                offset: CGSize(
                    width: -horizontal + .random(in: -10...8),
                    height: -vertical + .random(in: -8...8)
                ),
                rotation: .random(in: -14 ... -6)
            ),

            CardTransform(
                offset: CGSize(
                    width: horizontal + .random(in: -8...10),
                    height: -vertical + .random(in: -8...8)
                ),
                rotation: .random(in: 6 ... 14)
            ),

            CardTransform(
                offset: CGSize(
                    width: -horizontal + .random(in: -10...8),
                    height: vertical + .random(in: -8...10)
                ),
                rotation: .random(in: -6 ... 6)
            ),

            CardTransform(
                offset: CGSize(
                    width: horizontal + .random(in: -8...10),
                    height: vertical + .random(in: -8...10)
                ),
                rotation: .random(in: -8 ... 8)
            )

        ]

    }

}

private struct CardTransform {

    let offset: CGSize
    let rotation: Double

}

#Preview {

    ZStack {

        Rectangle()
            .fill(.gray.opacity(0.2))
            .frame(width: 760, height: 520)

        PaletteScatterView(
            colors: [
                Color(hex: "#A67F73"),
                Color(hex: "#4B4B57"),
                Color(hex: "#3A4C10"),
                Color(hex: "#6C8CBD")
            ],
            imageSize: CGSize(width: 4032, height: 3024)
        )

    }
    .frame(width: 900, height: 700)

}
