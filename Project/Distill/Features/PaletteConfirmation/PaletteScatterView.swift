//
//  PaletteScatterView.swift
//  distill
//
//  Created by Vitha Watson on 07/07/26.
//


import SwiftUI

struct PaletteScatterView: View {

    let colors: [Color]

    @State private var transforms: [CardTransform] = []

    var body: some View {
        GeometryReader { geometry in

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
            .onAppear {
                generateTransforms(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateTransforms(in size: CGSize) {

        guard transforms.isEmpty else { return }

        let horizontal = min(size.width * 0.34, 250)
        let vertical = min(size.height * 0.27, 185)

        transforms = [

            CardTransform(
                offset: CGSize(
                    width: -horizontal + .random(in: -18...10),
                    height: -vertical + .random(in: -12...12)
                ),
                rotation: .random(in: -14 ... -6)
            ),

            CardTransform(
                offset: CGSize(
                    width: horizontal + .random(in: -10...18),
                    height: -vertical + .random(in: -10...16)
                ),
                rotation: .random(in: 6 ... 14)
            ),

            CardTransform(
                offset: CGSize(
                    width: -horizontal + .random(in: -16...10),
                    height: vertical + .random(in: -10...18)
                ),
                rotation: .random(in: -6 ... 6)
            ),

            CardTransform(
                offset: CGSize(
                    width: horizontal + .random(in: -10...18),
                    height: vertical + .random(in: -12...16)
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
            ]
        )

    }
    .frame(width: 900, height: 700)

}