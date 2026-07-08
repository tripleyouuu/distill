import SwiftUI

/// A floating pill showing the locked palette colours, SF Symbol tools, and thickness controls.
struct CanvasToolbar: View {

    let viewModel: ArtBoardViewModel

    @State private var showThicknessPopover = false

    var body: some View {

        HStack(spacing: 12) {

            // MARK: - Tools
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ArtBoardViewModel.CanvasTool.allCases) { tool in
                        
                        Button {
                            if viewModel.selectedTool == tool {
                                showThicknessPopover.toggle()
                            } else {
                                viewModel.selectTool(tool)
                                showThicknessPopover = false
                            }
                        } label: {
                            Image(systemName: tool.iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(viewModel.selectedTool == tool ? .primary : .secondary)
                                .frame(width: 44, height: 44)
                                .background {
                                    if viewModel.selectedTool == tool {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray4).opacity(0.5))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tool.label)
                        .popover(isPresented: Binding(
                            get: { showThicknessPopover && viewModel.selectedTool == tool },
                            set: { showThicknessPopover = $0 }
                        )) {
                            ThicknessPickerPopover(viewModel: viewModel)
                                .presentationCompactAdaptation(.popover)
                        }
                        
                    }
                }
                .padding(.horizontal, 4)
            }
            // Constrain width so it doesn't take up the whole screen on iPad
            .frame(maxWidth: 320)
            
            Divider()
                .frame(height: 30)
            
            // MARK: - Colours

            HStack(spacing: 8) {

                ForEach(Array(viewModel.palette.enumerated()), id: \.offset) { index, color in

                    Button {

                        viewModel.selectColor(color)

                    } label: {

                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay {

                                if viewModel.selectedColor == color {

                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .frame(width: 32, height: 32)

                                }

                            }
                            .shadow(
                                color: .black.opacity(
                                    viewModel.selectedColor == color ? 0.3 : 0.12
                                ),
                                radius: 3,
                                y: 1
                            )

                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Colour \(index + 1)")

                }

            }
            .padding(.trailing, 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)

    }

}

struct ThicknessPickerPopover: View {
    @Bindable var viewModel: ArtBoardViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Preview Circle
            Circle()
                .fill(Color.primary)
                .frame(
                    width: 6 + (viewModel.selectedThicknessScalar * 24),
                    height: 6 + (viewModel.selectedThicknessScalar * 24)
                )
                .frame(width: 30, height: 30) // Fixed container to avoid layout shift
            
            Slider(value: $viewModel.selectedThicknessScalar, in: 0...1)
                .frame(width: 140)
                .tint(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {

    let vm = ArtBoardViewModel(
        referenceImage: UIImage(systemName: "photo")!,
        palette: [
            Color(hex: "#A67F73"),
            Color(hex: "#4B4B57"),
            Color(hex: "#3A4C10"),
            Color(hex: "#6C8CBD")
        ]
    )

    CanvasToolbar(viewModel: vm)
        .padding()
        .background(Color(.systemGray5))

}
