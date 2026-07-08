import SwiftUI
import PencilKit
import SwiftData
import os

@Observable
@MainActor
final class ArtBoardViewModel {

    // MARK: - Types

    enum CanvasTool: String, CaseIterable, Identifiable {
        case pen
        case marker
        case pencil
        case watercolor
        case crayon
        case monoline

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .pen: return "paintbrush.pointed.fill"
            case .marker: return "highlighter"
            case .pencil: return "pencil"
            case .watercolor: return "drop.fill"
            case .crayon: return "pencil.line"
            case .monoline: return "scribble.variable"
            }
        }

        var label: String {
            switch self {
            case .pen: return "Pen"
            case .marker: return "Marker"
            case .pencil: return "Pencil"
            case .watercolor: return "Watercolor"
            case .crayon: return "Crayon"
            case .monoline: return "Monoline"
            }
        }
    }


    // MARK: - Dependencies

    private let imageStore = ImageStore()

    private let logger = Logger(
        subsystem: "com.morad.Distill",
        category: "ArtBoard"
    )

    // MARK: - Stored inputs

    let referenceImage: UIImage
    let palette: [Color]

    /// When continuing from a saved entry, this holds the entry
    /// so we update it instead of creating a new one.
    var existingEntry: JournalEntry?

    // MARK: - Observable state

    var drawing = PKDrawing()
    var selectedColor: Color
    var selectedTool: CanvasTool = .pen
    var selectedThicknessScalar: CGFloat = 0.5
    var isReferenceVisible: Bool = true
    var showResetConfirmation: Bool = false

    // MARK: - Presented state

    var errorMessage: String?
    var isShowingError = false

    // MARK: - Init

    init(
        referenceImage: UIImage,
        palette: [Color],
        existingEntry: JournalEntry? = nil,
        existingDrawing: PKDrawing? = nil
    ) {
        self.referenceImage = referenceImage
        self.palette = palette
        self.existingEntry = existingEntry
        self.selectedColor = palette.first ?? .black

        if let existingDrawing {
            self.drawing = existingDrawing
        }
    }

    // MARK: - Tool mapping

    /// The actual PencilKit tool to pass to the canvas.
    var currentPKTool: PKTool {
        let uiColor = UIColor(selectedColor)
        let scalar = selectedThicknessScalar

        switch selectedTool {
        case .pen:
            let width = 2 + scalar * 16
            return PKInkingTool(.pen, color: uiColor, width: width)
        case .marker:
            let width = 8 + scalar * 28
            return PKInkingTool(.marker, color: uiColor, width: width)
        case .pencil:
            let width = 1 + scalar * 13
            return PKInkingTool(.pencil, color: uiColor, width: width)
        case .watercolor:
            let width = 10 + scalar * 50
            if #available(iOS 17.0, *) {
                return PKInkingTool(.watercolor, color: uiColor, width: width)
            } else {
                return PKInkingTool(.marker, color: uiColor, width: width)
            }
        case .crayon:
            let width = 4 + scalar * 20
            if #available(iOS 17.0, *) {
                return PKInkingTool(.crayon, color: uiColor, width: width)
            } else {
                return PKInkingTool(.pencil, color: uiColor, width: width)
            }
        case .monoline:
            let width = 2 + scalar * 18
            if #available(iOS 17.0, *) {
                return PKInkingTool(.monoline, color: uiColor, width: width)
            } else {
                return PKInkingTool(.pen, color: uiColor, width: width)
            }

        }
    }

    // MARK: - User actions

    func selectTool(_ tool: CanvasTool) {
        selectedTool = tool
    }
    


    func selectColor(_ color: Color) {
        selectedColor = color
    }

    func toggleReference() {
        isReferenceVisible.toggle()
    }

    func requestReset() {
        showResetConfirmation = true
    }

    func resetCanvas() {
        drawing = PKDrawing()
    }

    // MARK: - Rendering

    func renderPainting(size: CGSize) -> UIImage {
        let bounds = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)

            let strokes = drawing.image(from: bounds, scale: format.scale)
            strokes.draw(in: bounds)
        }
    }

    // MARK: - Save

    @discardableResult
    func save(into context: ModelContext, canvasSize: CGSize) -> Bool {

        do {

            let renderedPainting = renderPainting(size: canvasSize)
            let drawingData = drawing.dataRepresentation()

            if let existingEntry {

                // Update the existing entry (continuing a painting).
                let paintingIdentifier = try imageStore.savePainting(renderedPainting)

                // Remove old painting file.
                imageStore.deletePainting(identifier: existingEntry.paintingImageIdentifier)

                existingEntry.paintingImageIdentifier = paintingIdentifier
                existingEntry.drawingData = drawingData

                try context.save()

                logger.debug("Updated existing journal entry.")

            } else {

                // Create a brand new entry.
                let referenceIdentifier = try imageStore.saveReference(referenceImage)
                let paintingIdentifier = try imageStore.savePainting(renderedPainting)

                let entry = JournalEntry(
                    referenceImageIdentifier: referenceIdentifier,
                    paintingImageIdentifier: paintingIdentifier,
                    paletteHex: palette.map(\.hex),
                    drawingData: drawingData
                )

                context.insert(entry)

                try context.save()

                logger.debug("Journal entry saved with real painting.")

            }

            return true

        } catch {

            logger.error("Failed to save journal entry: \(error.localizedDescription)")
            fail("Couldn't save your painting.")

            return false

        }

    }

    // MARK: - Helpers

    private func fail(_ message: String) {
        errorMessage = message
        isShowingError = true
    }

}
