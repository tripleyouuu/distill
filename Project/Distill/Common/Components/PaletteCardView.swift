import SwiftUI

struct PaletteCardView: View {

    let color: Color
    let hexCode: String

    var body: some View {
        VStack(spacing: 0) {

            Rectangle()
                .fill(color)
                .aspectRatio(1, contentMode: .fit)

            VStack(alignment: .leading, spacing: 2) {

                Text(" DISTILL")
                    .font(.custom("Helvetica Neue", size: 10))
                    .fontWeight(.bold)
                    .foregroundStyle(.black)

                Text(" "+hexCode.uppercased())
                    .font(.custom("Helvetica Neue", size: 7))
                    .fontWeight(.regular)
                    .foregroundStyle(.black)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 7)
            .background(.white)

        }
        .frame(width: 100, height:150)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .shadow(radius: 8, y: 4)
    }
}

#Preview {
    ZStack {

        Color.gray.opacity(0.2)

        HStack(spacing: 24) {

            PaletteCardView(
                color: Color(hex: "#A68580"),
                hexCode: "#A68580"
            )

            PaletteCardView(
                color: Color(hex: "#6C8CBD"),
                hexCode: "#6C8CBD"
            )

            PaletteCardView(
                color: Color(hex: "#3F5310"),
                hexCode: "#3F5310"
            )

        }
        .padding()

    }
}
