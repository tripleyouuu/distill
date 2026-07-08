import Foundation
import SwiftData

@Model
final class JournalEntry {

    @Attribute(.unique)
    var id: UUID

    var createdAt: Date

    var referenceImageIdentifier: String

    var paintingImageIdentifier: String

    var paletteHex: [String]

    /// Raw `PKDrawing` data so the user can continue painting.
    var drawingData: Data?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        referenceImageIdentifier: String,
        paintingImageIdentifier: String,
        paletteHex: [String],
        drawingData: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.referenceImageIdentifier = referenceImageIdentifier
        self.paintingImageIdentifier = paintingImageIdentifier
        self.paletteHex = paletteHex
        self.drawingData = drawingData
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

}
