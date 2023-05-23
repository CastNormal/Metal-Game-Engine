import Cocoa

enum KeyboardEvents:Int {
    case W_key
    case A_key
    case S_key
    case D_key
    case key1
    case key2
    case ArrowLeft
    case ArrowRight
    case ArrowDown
    case ArrowUp
}

extension ViewController {
    /*
     override func mouseDown(with event: NSEvent) {
     print("mouse down")
     }*/
    
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { exit(0) } //used for pause
        keyEvent(keyCode: event.keyCode, event_type: true)
    }
    
    override func keyUp(with event: NSEvent) {
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
        case 123: //left arrow
            renderer.key_events[6] = event_type
        case 124: //right arrow
            renderer.key_events[7] = event_type
        case 125: //bottom arrow
            renderer.key_events[8] = event_type
        case 126: //top arrow
            renderer.key_events[9] = event_type
        case 49: //space
            break
        default: break
        }
    }
}
