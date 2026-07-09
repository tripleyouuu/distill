import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {

    @Binding
    var drawing: PKDrawing

    let tool: PKTool

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {

        let canvas = PKCanvasView()

        canvas.backgroundColor = .white
        canvas.isOpaque = true

        canvas.drawing = drawing
        canvas.tool = tool

        canvas.delegate = context.coordinator

        canvas.drawingPolicy = .pencilOnly

        canvas.isScrollEnabled = false
        canvas.alwaysBounceHorizontal = false
        canvas.alwaysBounceVertical = false

        return canvas
    }

    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {

        if canvas.drawing != drawing &&
            !context.coordinator.isUpdatingFromDelegate {

            canvas.drawing = drawing
        }

        canvas.tool = tool
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {

        var drawing: Binding<PKDrawing>

        var isUpdatingFromDelegate = false

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func canvasViewDrawingDidChange(
            _ canvasView: PKCanvasView
        ) {

            isUpdatingFromDelegate = true
            drawing.wrappedValue = canvasView.drawing
            isUpdatingFromDelegate = false

        }

    }

}

#Preview {
    PencilCanvasView(
        drawing: .constant(PKDrawing()),
        tool: PKInkingTool(.pen, color: .black, width: 8)
    )
    .frame(width: 650, height: 650)
}
