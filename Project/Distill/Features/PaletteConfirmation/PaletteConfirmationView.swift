import SwiftUI

struct PaletteConfirmationView: View {

    let referenceImage: UIImage
    let colors: [Color]

    let onChangeMoment: () -> Void
    let onStartPainting: () -> Void
    
    var body: some View {

        NavigationStack {

            ZStack {

                GridBackgroundView()

                VStack(spacing: 0) {

                    Spacer()

                    ZStack {

                        Image(uiImage: referenceImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 650, maxHeight:520)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 24)
                            )
                            .shadow(radius: 12)

                        PaletteScatterView(
                            colors: colors,
                            imageSize: referenceImage.size
                        )

                    }
                    .frame(maxWidth: 750, maxHeight:500)

                    Spacer()
                        .frame(height:50)

                    HStack(spacing: 14) {

                        Button {

                            onChangeMoment()

                        } label: {

                            Label(
                                "Change Moment",
                                systemImage: "arrow.counterclockwise"
                            )
                            .frame(width: 280)

                        }
                        .buttonStyle(.glass)
                        .tint(Color(.systemBackground))
                        .foregroundStyle(.primary)
                        .controlSize(.large)

                        Button {

                            onStartPainting()

                        } label: {

                            Label(
                                "Start Painting",
                                systemImage: "paintbrush"
                            )
                            .frame(width: 280)

                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                        .controlSize(.large)

                    }

                    Spacer()
                        .frame(height:10)

                    Text("Once you start painting, the chosen moment can't be changed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                }
                .padding(.horizontal, 50)

            }
            .navigationTitle("Today's Distillation")
            .navigationBarTitleDisplayMode(.inline)

        }

    }

}

#Preview {

    PaletteConfirmationView(
        referenceImage: UIImage(systemName: "photo")!,
        colors: [
            Color(hex: "#A67F73"),
            Color(hex: "#4B4B57"),
            Color(hex: "#3A4C10"),
            Color(hex: "#6C8CBD")
        ],
        onChangeMoment: {},
        onStartPainting: {}
    )

}
