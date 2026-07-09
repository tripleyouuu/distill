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

    @State
    private var shareService = ShareService()

    private let canvasSize = CGSize(width: 650, height: 650)

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

            ZStack {

                GridBackgroundView()

                PencilCanvasView(
                    drawing: $viewModel.drawing,
                    tool: viewModel.currentPKTool
                )
                .frame(width: 650, height: 650)
                .shadow(
                    color: .black.opacity(0.25),
                    radius: 4,
                    y: 4
                )
                .offset(y: -50)

                ReferencePhotoOverlay(
                    referenceImage: referenceImage,
                    isVisible: $viewModel.isReferenceVisible,
                    containerSize: geometry.size
                )

                VStack {

                    Spacer()

                    CanvasToolbar(viewModel: viewModel)
                        .padding(.bottom, 5)

                }

            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

        }
        .navigationBarBackButtonHidden()

        .toolbar {

            ToolbarItem(placement: .topBarLeading) {

                Button {

                    finish()

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

                        shareCurrentPainting()

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

        .sheet(isPresented: $shareService.isShowingShareSheet) {

            ShareSheet(items: shareService.itemsToShare)

        }

    }

    // MARK: - Actions

    private func finish() {

        if viewModel.save(
            into: modelContext,
            canvasSize: canvasSize
        ) {

            onFinish()

        }

    }

    private func shareCurrentPainting() {

        let rendered = viewModel.renderPainting(
            size: canvasSize
        )

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
