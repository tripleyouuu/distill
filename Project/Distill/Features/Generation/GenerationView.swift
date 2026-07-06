import SwiftUI
import SwiftData

/// Loading / "generation" screen shown after a photo is picked.
///
/// The color extraction is effectively instant, but the design calls for a
/// deliberate pause, so this screen stays up for a *minimum* of `minimumDuration`
/// while the real work runs underneath. When both finish, it dismisses back
/// to Home, where the new painting appears in the grid.
struct GenerationView: View {

    let referenceImage: UIImage
    let viewModel: HomeViewModel

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var isPulsing = false
    @State private var hasStarted = false

    private let minimumDuration: Duration = .seconds(5)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray3)
                    .ignoresSafeArea()

                Image(uiImage: referenceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 560, maxHeight: 460)
                    .overlay { Color.black.opacity(0.35) }
                    .overlay {
                        Text("Distilling Moment…")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .opacity(isPulsing ? 0.5 : 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityElement()
                    .accessibilityLabel("Distilling moment")
                    .accessibilityAddTraits(.updatesFrequently)
            }
            .navigationTitle("Today's Moment")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
        .task {
            // `.task` on a NavigationStack inside a fullScreenCover can fire
            // more than once; make sure the pipeline runs exactly once.
            guard !hasStarted else { return }
            hasStarted = true
            startPulsing()
            await runGeneration()
        }
    }

    private func startPulsing() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }

    private func runGeneration() async {
        let start = ContinuousClock.now

        await viewModel.process(referenceImage, into: modelContext)

        // Hold the screen for at least the design's minimum duration.
        let elapsed = ContinuousClock.now - start
        if elapsed < minimumDuration {
            try? await Task.sleep(for: minimumDuration - elapsed)
        }

        dismiss()
    }
}

#Preview {
    GenerationView(
        referenceImage: UIImage(systemName: "photo")!,
        viewModel: HomeViewModel()
    )
    .modelContainer(for: JournalEntry.self, inMemory: true)
}
