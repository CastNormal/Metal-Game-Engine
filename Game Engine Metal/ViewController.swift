import Cocoa
import MetalKit

enum KeyboardEvents:Int {
    case W_key
    case A_key
    case S_key
    case D_key
    case key1
    case key2
    case ArrowDown
    case ArrowUp
}

class ViewController: NSViewController {
    var mtkView: MTKView!
    var renderer: Renderer!
    var skip = false
    var on_screen: Bool = false
    var prev_pos = CGPoint(x: 400, y: 300)
    
    override func loadView() {
        self.view = MTKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView = self.view as? MTKView
        
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        mtkView.clearColor = MTLClearColor(red: 0, green: 1, blue: 0, alpha: 1)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if NSApplication.shared.keyWindow != self.view.window { return $0 }
            self.keyDown(with: $0)
            return nil
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            self.keyUp(with: $0)
            return nil
        }

        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { (event) -> NSEvent? in

            let delta = Float(1.0/60.0)
            self.renderer.camera.orientation.x += Float(event.deltaX) * delta
            self.renderer.camera.orientation.z += Float(event.deltaY) * delta

            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { _ in
            //self.mouseExited(with: $0)
            //NSCursor.hide()
            self.on_screen = true
            return nil
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { _ in
            //CGDisplayMoveCursorToPoint(CGDirectDisplayID(), self.renderer.mouse.mouse_origin)
            return nil
        }
        
        renderer = Renderer(mtkView: mtkView)
        mtkView.delegate = renderer
        
        CGAssociateMouseAndMouseCursorPosition(0)
        NSCursor.hide()
    }

    override var acceptsFirstResponder: Bool { return true }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        return true
    }
    /*
    override func mouseDown(with event: NSEvent) {
        print("mouse down")
    }*/
    
    
    override func keyDown(with event: NSEvent) {
        //print("keydown")
        if event.keyCode == 53 { exit(0) }
        keyEvent(keyCode: event.keyCode, event_type: true)
    }
    
    override func keyUp(with event: NSEvent) {
        //print("keyup")
        keyEvent(keyCode: event.keyCode, event_type: false)
    }
    
    func keyEvent(keyCode: UInt16, event_type: Bool) {
        switch keyCode {
        case 13: //w
            renderer.key_events[0] = event_type
        case 0: //a
            renderer.key_events[1] = event_type
        case 1: //s
            renderer.key_events[2] = event_type
        case 2: //d
            renderer.key_events[3] = event_type
        case 18:
            renderer.key_events[4] = event_type
        case 19:
            renderer.key_events[5] = event_type
        case 125:
            renderer.key_events[6] = event_type
        case 126:
            renderer.key_events[7] = event_type
        case 49: //space
            break
        default: break
        }
    }

}

