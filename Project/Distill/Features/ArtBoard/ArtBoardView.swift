import SwiftUI
import PencilKit
import SwiftData

struct ArtBoardView: View {

    let referenceImage: UIImage
    let palette: [Color]
    let onFinish: () -> Void

    @State
    private var viewModel: ArtBoardViewModel

    @Environment(\.modelContext)
    private var modelContext

    private let shareService = ShareService()

    private let canvasPadding: CGFloat = 40

    init(
        referenceImage: UIImage,
        palette: [Color],
        onFinish: @escaping () -> Void,
        existingEntry: JournalEntry? = nil,
        existingDrawing: PKDrawing? = nil
    ) {
        self.referenceImage = referenceImage
        self.palette = palette
        self.onFinish = onFinish

        let vm = ArtBoardViewModel(
            referenceImage: referenceImage,
            palette: palette,
            existingEntry: existingEntry,
            existingDrawing: existingDrawing
        )

        _viewModel = State(initialValue: vm)
    }

    var body: some View {

        @Bindable var viewModel = viewModel

        GeometryReader { geometry in

            let size = canvasSize(for: geometry)

            ZStack {

                GridBackgroundView()

                PencilCanvasView(
                    drawing: $viewModel.drawing,
                    tool: viewModel.currentPKTool
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
                .padding(canvasPadding)

                ReferencePhotoOverlay(
                    referenceImage: referenceImage,
                    isVisible: $viewModel.isReferenceVisible,
                    containerSize: geometry.size
                )

                VStack {

                    Spacer()

                    CanvasToolbar(viewModel: viewModel)
                        .padding(.bottom, canvasPadding * 0.4)

                }

            }
            .navigationTitle("Painting")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button {

                        finish(canvasSize: size)

                    } label: {

                        Image(systemName: "chevron.left")

                    }
                    .accessibilityLabel("Back")

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Menu {

                        Button {

                            viewModel.toggleReference()

                        } label: {
                            Label(
                                "Toggle Reference",
                                systemImage: "eye"
                            )
                        }

                        Button {

                            shareCurrentPainting(canvasSize: size)

                        } label: {
                            Label(
                                "Share Painting",
                                systemImage: "square.and.arrow.up"
                            )
                        }

                        Button(role: .destructive) {

                            viewModel.requestReset()

                        } label: {
                            Label(
                                "Reset Canvas",
                                systemImage: "trash"
                            )
                        }

                    } label: {

                        Image(systemName: "ellipsis")

                    }
                    .accessibilityLabel("More")

                }

            }
            .alert(
                "Reset Canvas?",
                isPresented: $viewModel.showResetConfirmation
            ) {

                Button("Cancel", role: .cancel) { }

                Button("Reset", role: .destructive) {
                    viewModel.resetCanvas()
                }

            } message: {
                Text("This can't be undone.")
            }
            .alert(
                "Something went wrong",
                isPresented: $viewModel.isShowingError,
                presenting: viewModel.errorMessage
            ) { _ in
                Button("OK") { }
            } message: { message in
                Text(message)
            }

        }

    }

    // MARK: - Helpers

    private func canvasSize(for geometry: GeometryProxy) -> CGSize {

        CGSize(
            width: max(geometry.size.width - canvasPadding * 2, 1),
            height: max(geometry.size.height - canvasPadding * 2, 1)
        )

    }

    // MARK: - Actions

    private func finish(canvasSize: CGSize) {

        if viewModel.drawing.strokes.isEmpty && viewModel.existingEntry == nil {
            onFinish()
        } else if viewModel.drawing.strokes.isEmpty && viewModel.existingEntry != nil {
            // Continuing but didn't draw anything new — just dismiss.
            onFinish()
        } else if viewModel.save(into: modelContext, canvasSize: canvasSize) {
            onFinish()
        }

    }

    private func shareCurrentPainting(canvasSize: CGSize) {

        let rendered = viewModel.renderPainting(size: canvasSize)

        shareService.share(rendered)

    }

}

#Preview {

    NavigationStack {

        ArtBoardView(
            referenceImage: UIImage(systemName: "photo")!,
            palette: [
                Color(hex: "#A67F73"),
                Color(hex: "#4B4B57"),
                Color(hex: "#3A4C10"),
                Color(hex: "#6C8CBD")
            ],
            onFinish: {}
        )

    }
    .modelContainer(
        for: JournalEntry.self,
        inMemory: true
    )

}
