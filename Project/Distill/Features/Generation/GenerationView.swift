import SwiftUI
import SwiftData
import PhotosUI

/// Loading / "generation" screen shown after a photo is picked.
///
/// The color extraction is effectively instant, but the design calls for a
/// deliberate pause, so this screen stays up for a minimum amount of time
/// before transitioning to the palette confirmation screen.
struct GenerationView: View {

    let viewModel: HomeViewModel

    @State
    private var currentImage: UIImage

    init(
        referenceImage: UIImage,
        viewModel: HomeViewModel
    ) {
        self.viewModel = viewModel
        _currentImage = State(initialValue: referenceImage)
    }

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State
    private var extractedColors: [Color] = []

    @State
    private var hasStarted = false

    @State
    private var isPulsing = false

    @State
    private var showPaletteConfirmation = false

    @State
    private var showArtBoard = false

    @State
    private var showPhotoPicker = false

    @State
    private var selectedPhotoItem: PhotosPickerItem?

    private let minimumDuration: Duration = .milliseconds(
        Int.random(in: 1500...3500)
    )

    var body: some View {

        NavigationStack {

            ZStack {

                Color(.systemGray3)
                    .ignoresSafeArea()

                Image(uiImage: currentImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 560, maxHeight: 460)
                    .overlay {
                        Color.black.opacity(0.35)
                    }
                    .overlay {
                        Text("Distilling Moment…")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .opacity(isPulsing ? 0.5 : 1)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24)
                    )

            }
            .navigationTitle("Today's Moment")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .navigationDestination(isPresented: $showPaletteConfirmation) {

                PaletteConfirmationView(
                    referenceImage: currentImage,
                    colors: extractedColors,
                    onChangeMoment: {
                        showPhotoPicker = true
                    },
                    onStartPainting: {
                        showArtBoard = true
                    },
                    onCancel: {
                        dismiss()
                    }
                )

            }
            .navigationDestination(isPresented: $showArtBoard) {

                ArtBoardView(
                    referenceImage: currentImage,
                    palette: extractedColors,
                    onFinish: {
                        dismiss()
                    }
                )

            }

        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .photosPickerDisabledCapabilities(.collectionNavigation)
        .onChange(of: selectedPhotoItem) { _, newItem in

            guard let newItem else { return }

            Task {

                defer {
                    selectedPhotoItem = nil
                }

                if let image = await viewModel.loadImage(from: newItem) {

                    currentImage = image

                    extractedColors = []

                    showPaletteConfirmation = false

                    showArtBoard = false

                    hasStarted = false

                    isPulsing = false

                    startPulsing()

                    await runGeneration()

                }

            }

        }
        .onAppear {

            guard !hasStarted else { return }

            hasStarted = true

            startPulsing()

            Task {
                await runGeneration()
            }

        }

    }

    private func startPulsing() {

        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }

    }

    private func runGeneration() async {

        let start = ContinuousClock.now

        do {

            extractedColors = try await viewModel.extractPalette(
                from: currentImage
            )

            let elapsed = ContinuousClock.now - start

            if elapsed < minimumDuration {
                try? await Task.sleep(
                    for: minimumDuration - elapsed
                )
            }

            showPaletteConfirmation = true

        } catch {

            viewModel.errorMessage =
                "Something went wrong. Please try again."

            viewModel.isShowingError = true

            dismiss()

        }

    }

}

#Preview {

    GenerationView(
        referenceImage: UIImage(systemName: "photo")!,
        viewModel: HomeViewModel()
    )
    .modelContainer(
        for: JournalEntry.self,
        inMemory: true
    )

}
