
import MetalKit

class InputView: MTKView {

    let input = InputManager()

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        window?.makeFirstResponder(self)

        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.didResignKeyNotification,
            object: nil
        )

        if let window {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowLostFocus),
                name: NSWindow.didResignKeyNotification,
                object: window
            )
        }
    }

    @objc func windowLostFocus() {
        input.reset()
    }
    
    override func flagsChanged(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        if modifiers.contains(.shift) {
            input.keyDown(56)
        } else {
            input.keyUp(56)
        }
            
        super.flagsChanged(with: event)
    }

    override func keyDown(with event: NSEvent) {

        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
            return
        }

        if KeyboardEvents(rawValue: event.keyCode) != nil {
            input.keyDown(event.keyCode)
        } else {
            super.keyDown(with: event)
        }
    }

    override func keyUp(with event: NSEvent) {

        if KeyboardEvents(rawValue: event.keyCode) != nil {
            input.keyUp(event.keyCode)
        } else {
            super.keyUp(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.rightMouseDown(with: event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        input.addMouseMovement(x: Float(event.deltaX), y: Float(-event.deltaY))
    }

    override func resignFirstResponder() -> Bool {
        input.reset()
        return super.resignFirstResponder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
