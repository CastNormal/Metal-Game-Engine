import Cocoa
import MetalKit

@_cdecl("create_window")
func create_window(title: UnsafePointer<CChar>) {
    let shared_application = NSApplication.shared
    let app_delegate = AppDelegate(title: String(cString: title))
    shared_application.delegate = app_delegate
    shared_application.run()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var device: MTLDevice!
    let title: String
    
    init?(title: String) {
        self.title = title
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentRect = NSRect(x: 300, y: 300, width: 800, height: 600)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .resizable, .miniaturizable, .closable],
            backing: .buffered,
            defer: false)
        
        window.title = title
        
        let controller = ViewController()
        
        device = MTLCreateSystemDefaultDevice()
        window.makeKeyAndOrderFront(1)
        window.contentViewController = controller
        
        //Game Controller
        
        //NotificationCenter.default.addObserver(self, selector: #selector(connectController), name: NSNotification.Name.GCControllerDidConnect, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(disconnectController), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


}

