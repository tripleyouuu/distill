import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {

    @Binding
    var drawing: PKDrawing

    let tool: PKTool

    private let canvasSize = CGSize(width: 650, height: 650)

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> CanvasHostView {
        let hostView = CanvasHostView(canvasSize: canvasSize)
        hostView.configure(
            coordinator: context.coordinator,
            drawing: drawing,
            tool: tool
        )
        return hostView
    }

    func updateUIView(_ uiView: CanvasHostView, context: Context) {
        uiView.update(
            drawing: drawing,
            tool: tool,
            coordinator: context.coordinator
        )
    }

    // MARK: - Hosting View

    final class CanvasHostView: UIView {

        private let canvasSize: CGSize

        let scrollView = UIScrollView()
        let contentView = UIView()
        let canvasView = PKCanvasView()

        private var didPerformInitialLayout = false

        init(canvasSize: CGSize) {
            self.canvasSize = canvasSize
            super.init(frame: .zero)
            setUpViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configure(
            coordinator: Coordinator,
            drawing: PKDrawing,
            tool: PKTool
        ) {
            scrollView.delegate = coordinator
            canvasView.delegate = coordinator

            canvasView.drawing = drawing
            canvasView.tool = tool

            coordinator.canvasView = canvasView
            coordinator.scrollView = scrollView
            coordinator.contentView = contentView
        }

        func update(
            drawing: PKDrawing,
            tool: PKTool,
            coordinator: Coordinator
        ) {
            if canvasView.drawing != drawing,
               !coordinator.isUpdatingFromDelegate {
                canvasView.drawing = drawing
            }

            canvasView.tool = tool

            if drawing.strokes.isEmpty, coordinator.hasDrawnBefore {
                coordinator.hasDrawnBefore = false
                resetZoom(animated: true)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            scrollView.frame = bounds

            if !didPerformInitialLayout {
                contentView.frame = CGRect(
                    origin: .zero,
                    size: canvasSize
                )

                canvasView.frame = contentView.bounds
                scrollView.contentSize = canvasSize
                scrollView.zoomScale = 1.0
                centerContentIfNeeded()

                didPerformInitialLayout = true
            } else {
                canvasView.frame = contentView.bounds
                centerContentIfNeeded()
            }
        }

        private func setUpViews() {
            backgroundColor = .clear

            scrollView.backgroundColor = .clear
            scrollView.delegate = nil
            scrollView.minimumZoomScale = 0.5
            scrollView.maximumZoomScale = 5.0
            scrollView.zoomScale = 1.0
            scrollView.bouncesZoom = true
            scrollView.alwaysBounceHorizontal = true
            scrollView.alwaysBounceVertical = true
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.clipsToBounds = false

            contentView.backgroundColor = .clear
            contentView.isUserInteractionEnabled = true

            canvasView.backgroundColor = .white
            canvasView.isOpaque = true
            canvasView.drawingPolicy = .pencilOnly
            canvasView.isScrollEnabled = false
            canvasView.alwaysBounceHorizontal = false
            canvasView.alwaysBounceVertical = false

            addSubview(scrollView)
            scrollView.addSubview(contentView)
            contentView.addSubview(canvasView)
        }

        private func resetZoom(animated: Bool) {
            scrollView.setZoomScale(1.0, animated: animated)
            scrollView.setContentOffset(.zero, animated: animated)
            centerContentIfNeeded()
        }

        private func centerContentIfNeeded() {
            let horizontalInset = max(
                (scrollView.bounds.width - contentView.frame.width) / 2,
                0
            )

            let verticalInset = max(
                (scrollView.bounds.height - contentView.frame.height) / 2,
                0
            )

            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate, PKCanvasViewDelegate {

        var drawing: Binding<PKDrawing>
        weak var canvasView: PKCanvasView?
        weak var scrollView: UIScrollView?
        weak var contentView: UIView?

        var isUpdatingFromDelegate = false
        var hasDrawnBefore = false

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            contentView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let contentView else { return }

            let horizontalInset = max(
                (scrollView.bounds.width - contentView.frame.width) / 2,
                0
            )

            let verticalInset = max(
                (scrollView.bounds.height - contentView.frame.height) / 2,
                0
            )

            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            drawing.wrappedValue = canvasView.drawing
            if !canvasView.drawing.strokes.isEmpty {
                hasDrawnBefore = true
            }
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
    .background(Color.gray.opacity(0.2))
}
