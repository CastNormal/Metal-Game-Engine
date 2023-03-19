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
        let contentRect = NSRect(x: 0, y: 0, width: 800, height: 600)
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
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


}

