import Cocoa
import MetalKit
import GameController

@available(macOS 26.4, *)
class ViewController: NSViewController {

    var mtkView: InputView!
    var renderer: Renderer!

    override func loadView() {
        self.view = InputView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView = self.view as? InputView

        mtkView.device = MTLCreateSystemDefaultDevice()

        mtkView.clearColor = MTLClearColor(red: 0, green: 1, blue: 0, alpha: 1)

        renderer = Renderer(view: mtkView)
        mtkView.delegate = renderer
    }
}
