import SwiftUI
import PencilKit

/// A `UIViewRepresentable` wrapping `PKCanvasView`.
/// Does **not** show the system `PKToolPicker`, to strictly enforce
/// the 4-colour locked palette and custom tools.
struct PencilCanvasView: UIViewRepresentable {

    @Binding
    var drawing: PKDrawing

    let tool: PKTool

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {

        let canvasView = PKCanvasView()

        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        canvasView.drawing = drawing
        canvasView.tool = tool
        canvasView.delegate = context.coordinator

        return canvasView

    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {

        // Only update if it wasn't triggered by the delegate itself
        // (prevents weird feedback loops when drawing fast).
        if uiView.drawing != drawing, !context.coordinator.isUpdatingFromDelegate {
            uiView.drawing = drawing
        }

        uiView.tool = tool

    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate {

        var drawing: Binding<PKDrawing>
        var isUpdatingFromDelegate = false

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            drawing.wrappedValue = canvasView.drawing
            isUpdatingFromDelegate = false
        }

    }

}
