import SwiftUI
import UIKit


@available(iOS 18.0, *)
struct SwipePanGestureRecognizer: UIGestureRecognizerRepresentable {
    let minimumDistance: Double
    let onChanged: (CGSize) -> Void
    let onEnded: (CGSize) -> Void
    let updateDragging: (Bool) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.minimumNumberOfTouches = 1
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view)
        let translationSize = CGSize(width: translation.x, height: translation.y)
        switch recognizer.state {
        case .began:
            // Check minimum distance before starting
            let distance = sqrt(translation.x * translation.x + translation.y * translation.y)
            if distance >= minimumDistance {
                updateDragging(true)
                onChanged(translationSize)
            }
        case .changed:
            let distance = sqrt(translation.x * translation.x + translation.y * translation.y)
            if distance >= minimumDistance {
                updateDragging(true)
                onChanged(translationSize)
            }
        case .ended,
             .cancelled,
             .failed:
            updateDragging(false)
            onEnded(translationSize)
        default:
            break
        }
    }

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        )
        -> Bool {
            false
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }

            let velocity = panRecognizer.velocity(in: gestureRecognizer.view)
            return abs(velocity.y) < abs(velocity.x)
        }
    }
}

struct SwipeGestureModifier: ViewModifier {
    let minimumDistance: Double
    let onChanged: (CGSize) -> Void
    let onEnded: (CGSize) -> Void
    let updateDragging: (Bool) -> Void

    init(
        minimumDistance: Double,
        onChanged: @escaping (CGSize) -> Void,
        onEnded: @escaping (CGSize) -> Void,
        updateDragging: @escaping (Bool) -> Void
    ) {
        self.minimumDistance = minimumDistance
        self.onChanged = onChanged
        self.onEnded = onEnded
        self.updateDragging = updateDragging
    }

    @GestureState var isDragging = false

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(SwipePanGestureRecognizer(
                minimumDistance: minimumDistance,
                onChanged: onChanged,
                onEnded: onEnded,
                updateDragging: updateDragging
            ))
        } else {
            content.gesture (
                DragGesture(minimumDistance: minimumDistance, coordinateSpace: .global)
                    .updating($isDragging) { _, isDragging, _ in
                        isDragging = true
                    }
                    .onChanged {
                      onChanged($0.translation)
                    }
                    .onEnded {
                      onEnded($0.translation)
                    }
            )
            .valueChanged(of: isDragging) { newValue in
                updateDragging(newValue)
            }
        }
    }
}
