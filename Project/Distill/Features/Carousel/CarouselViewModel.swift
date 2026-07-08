import SwiftUI
import SwiftData

@Observable
@MainActor
final class CarouselViewModel {

    // MARK: - Dependencies

    private let imageStore = ImageStore()

    // MARK: - Image loading

    /// Returns the painting or reference image based on the current toggle state.
    func displayedImage(for entry: JournalEntry, showingReference: Bool) -> UIImage? {
        if showingReference {
            return imageStore.loadReference(identifier: entry.referenceImageIdentifier)
        }
        return imageStore.loadPainting(identifier: entry.paintingImageIdentifier)
    }

    /// Loads the reference photo for continuing a painting.
    func loadReference(for entry: JournalEntry) -> UIImage? {
        imageStore.loadReference(identifier: entry.referenceImageIdentifier)
    }

    // MARK: - Title

    /// "Today" for entries created today, otherwise the full formatted date.
    func title(for entry: JournalEntry) -> String {
        if entry.isToday { return "Today" }
        return entry.createdAt.formatted(date: .complete, time: .omitted)
    }

    // MARK: - Deletion

    /// Deletes the entry's files from disk and removes the SwiftData record.
    /// Throws if the context save fails.
    /// The caller (View) is responsible for dismissing after this returns.
    func delete(_ entry: JournalEntry, from context: ModelContext) throws {
        imageStore.deletePainting(identifier: entry.paintingImageIdentifier)
        imageStore.deleteReference(identifier: entry.referenceImageIdentifier)
        context.delete(entry)
        try context.save()
    }
}
