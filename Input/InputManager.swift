
import AppKit
import simd

enum KeyboardEvents: UInt16 {
    case W_key = 13
    case A_key = 0
    case S_key = 1
    case D_key = 2
    case Space_key = 49
    case Shift_key = 56
}

class InputManager {

    private var pressedKeys: Set<UInt16> = []
    private var mouseDelta = SIMD2<Float>(0, 0)

    func keyDown(_ keyCode: UInt16) {
        pressedKeys.insert(keyCode)
    }

    func keyUp(_ keyCode: UInt16) {
        pressedKeys.remove(keyCode)
    }

    func isPressed(_ key: KeyboardEvents) -> Bool {
        return pressedKeys.contains(key.rawValue)
    }

    func addMouseMovement(x: Float, y: Float) {
        mouseDelta += SIMD2<Float>(x, y)
    }

    func consumeMouseMovement() -> SIMD2<Float> {
        let delta = mouseDelta
        mouseDelta = .zero
        return delta
    }

    func reset() {
        pressedKeys.removeAll()
        mouseDelta = .zero
    }
}
