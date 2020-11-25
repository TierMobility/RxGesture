
#if canImport(UIKit)

import UIKit.UIGestureRecognizerSubclass
import RxSwift
import RxCocoa

@available(iOS 9.0, *)
public class ForceTouchGestureRecognizer: UIGestureRecognizer {

    private var touch: UITouch?
    public var force: CGFloat {
        return touch?.force ?? 0
    }
    
    public var maximumPossibleForce: CGFloat {
        return touch?.maximumPossibleForce ?? 0
    }

    public var absoluteFractionCompleted: CGFloat {
        guard maximumPossibleForce > 0 else {
            return 0
        }
        return force / maximumPossibleForce
    }

    public var minimumFractionCompletedRequired: CGFloat = 0
    public var maximumFractionCompletedRequired: CGFloat = 1

    public var fractionCompleted: CGFloat {
        return lerp(
            mapMin: minimumFractionCompletedRequired, to: 0,
            mapMax: maximumFractionCompletedRequired, to: 1,
            value: absoluteFractionCompleted
        )
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        guard state == .possible else { return }
        guard touch == nil else { return }
        guard let first = touches.first(where: { $0.phase == .began }) else { return }
        touch = first
        state = .began
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let touch = touch, touches.contains(touch), touch.phase == .moved else { return }
        state = .changed
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard let touch = touch, touches.contains(touch), touch.phase == .ended else { return }
        self.touch = nil
        state = .ended
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        guard let touch = touch, touches.contains(touch), touch.phase == .cancelled else { return }
        self.touch = nil
        state = .cancelled
    }
}

@available(iOS 9.0, *)
public typealias ForceTouchConfiguration = Configuration<ForceTouchGestureRecognizer>
@available(iOS 9.0, *)
public typealias ForceTouchControlEvent = ControlEvent<ForceTouchGestureRecognizer>
@available(iOS 9.0, *)
public typealias ForceTouchObservable = Observable<ForceTouchGestureRecognizer>

@available(iOS 9.0, *)
extension Factory where Gesture == RxGestureRecognizer {

    /**
     Returns an `AnyFactory` for `ForceTouchGestureRecognizer`
     - parameter configuration: A closure that allows to fully configure the gesture recognizer
     */
    public static func forceTouch(configuration: ForceTouchConfiguration? = nil) -> AnyFactory {
        return make(configuration: configuration).abstracted()
    }
}

@available(iOS 9.0, *)
extension Reactive where Base: RxGestureView {

    /**
     Returns an observable `ForceTouchGestureRecognizer` events sequence
     - parameter configuration: A closure that allows to fully configure the gesture recognizer
     */
    public func forceTouchGesture(configuration: ForceTouchConfiguration? = nil) -> ForceTouchControlEvent {
        return gesture(make(configuration: configuration))
    }
}

@available(iOS 9.0, *)
extension ObservableType where Element: ForceTouchGestureRecognizer {

    /**
     Maps the observable `GestureRecognizer` events sequence to an observable sequence of force values.
     */
    public func asForce() -> Observable<CGFloat> {
        return self.map { $0.force }
    }

    public func when(fractionCompletedExceeds threshold: CGFloat) -> Observable<Element> {
        let source = asObservable()
        return source
            .when(.began)
            .flatMapLatest { [unowned source] _ in
                return source
                    .when(.changed)
                    .filter {
                        if threshold == 0 {
                            return $0.fractionCompleted > threshold
                        } else {
                            return $0.fractionCompleted >= threshold
                        }
                    }
                    .take(1)
            }
    }
}

private func lerp<T : FloatingPoint>(_ v0: T, _ v1: T, _ t: T) -> T {
    return v0 + (v1 - v0) * t
}

private func lerp<T : FloatingPoint>(mapMin: T, to min: T, mapMax: T, to max: T, value: T) -> T {
    return  lerp(min, max, (value - mapMin) / (mapMax - mapMin))
}

#endif
