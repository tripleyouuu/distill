import SwiftUI
import PhotosUI
import SwiftData
import os

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Presented state

    var errorMessage: String?
    var isShowingError = false

    // MARK: - Dependencies

    private let imageStore = ImageStore()
    private let generator = PaintingGenerator()
    private let extractor = DominantColorExtractor()

    private let logger = Logger(
        subsystem: "com.morad.Distill",
        category: "ColorExtraction"
    )

    // MARK: - Painting loading

    func loadPainting(identifier: String) -> UIImage? {
        imageStore.loadPainting(identifier: identifier)
    }

    // MARK: - Photo pipeline

    /// Turns a picked photo into a saved `JournalEntry`:
    /// load → resize → extract colors → generate painting → persist.
    func process(_ item: PhotosPickerItem, into context: ModelContext) async {
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let originalImage = UIImage(data: data)
            else {
                fail("Couldn't load that photo. Try a different one.")
                return
            }

            // Downscale off the main actor so the UI never stalls.
            let targetSize = CGSize(width: 100, height: 100)
            let resizedImage = await Task.detached(priority: .userInitiated) {
                await originalImage.resize(to: targetSize)
            }.value

            guard let resizedImage else {
                fail("Failed to process the image.\nPlease try again.")
                return
            }

            let colors = try await extractor.extract(from: resizedImage)
            logger.debug("Extracted \(colors.count) colors")

            let generatedPainting = generator.generate(from: colors)

            let referenceIdentifier = try imageStore.saveReference(originalImage)
            let paintingIdentifier = try imageStore.savePainting(generatedPainting)

            let entry = JournalEntry(
                referenceImageIdentifier: referenceIdentifier,
                paintingImageIdentifier: paintingIdentifier,
                paletteHex: colors.map(\.hex)
            )
            context.insert(entry)

            try context.save()
            logger.debug("Journal entry saved successfully.")

        } catch {
            logger.error("Color extraction failed: \(error.localizedDescription)")
            fail("Something went wrong. Please try again.")
        }
    }

    // MARK: - Helpers

    private func fail(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}
