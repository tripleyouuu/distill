import SwiftUI

/// Floating liquid-glass toolbar for painting tools and palette selection.
struct CanvasToolbar: View {

    let viewModel: ArtBoardViewModel

    @State private var showThicknessPopover = false
    @State private var dragOffset: CGSize = .zero
    @State private var basePosition = CGSize(width: 0, height: 0)
    
    private var dragBounds: (
        x: ClosedRange<CGFloat>,
        y: ClosedRange<CGFloat>
    ) {

        (
            x: (-520)...520,
            y: (-320)...320
        )

    }
    
    var body: some View {

        HStack(spacing: 18) {

            // MARK: - Tools

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
                            .symbolVariant(
                                viewModel.selectedTool == tool ? .fill : .none
                            )
                            .font(
                                .system(
                                    size: 22,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                viewModel.selectedTool == tool ? .primary : .secondary
                            )
                            .scaleEffect(viewModel.selectedTool == tool ? 1.22 : 1.0)
                            .frame(width: 52, height: 52)
                            .contentShape(Rectangle())
                            .animation(.snappy(duration: 0.18), value: viewModel.selectedTool)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tool.label)
                    .popover(
                        isPresented: Binding(
                            get: { showThicknessPopover && viewModel.selectedTool == tool },
                            set: { showThicknessPopover = $0 }
                        )
                    ) {
                        ThicknessPickerPopover(viewModel: viewModel)
                            .presentationCompactAdaptation(.popover)
                    }

                }

            }

            Divider()
                .frame(height: 34)

            // MARK: - Colours

            HStack(spacing: 10) {

                ForEach(Array(viewModel.palette.enumerated()), id: \.offset) { index, color in

                    Button {
                        withAnimation(.snappy(duration: 0.15)) {
                            viewModel.selectColor(color)
                        }
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(
                                width: viewModel.selectedColor == color ? 30 : 20,
                                height: viewModel.selectedColor == color ? 30 : 20
                            )
                            .shadow(
                                color: .black.opacity(0.14),
                                radius: 2,
                                y: 1
                            )
                            .animation(.snappy(duration: 0.15), value: viewModel.selectedColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Colour \(index + 1)")

                }

            }

        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(height: 70)
        .glassEffect(in: .rect(cornerRadius: 34))
        .offset(
            x: basePosition.width + dragOffset.width,
            y: basePosition.height + dragOffset.height
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    dragOffset = value.translation
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

struct ThicknessPickerPopover: View {

    @Bindable var viewModel: ArtBoardViewModel

    var body: some View {

        HStack(spacing: 20) {

            Circle()
                .fill(.primary)
                .frame(
                    width: 8 + (viewModel.selectedThicknessScalar * 30),
                    height: 8 + (viewModel.selectedThicknessScalar * 30)
                )
                .frame(width: 40, height: 40)

            Slider(
                value: $viewModel.selectedThicknessScalar,
                in: 0...1
            )
            .frame(width: 180)
            .tint(.primary)

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)

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

    ZStack {
        Color(.systemGray5)
        CanvasToolbar(viewModel: vm)
            .padding()
    }

}
