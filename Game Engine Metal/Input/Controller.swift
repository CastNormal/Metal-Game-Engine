import Cocoa
import GameController

struct Controller {
    static var is_controller: Int = 0
    static var leftThumbstick_x: Float = 0
    static var leftThumbstick_y: Float = 0
    static var rightThumbstick_x: Float = 0
    static var rightThumbstick_y: Float = 0
}

extension AppDelegate {
    @objc func connectController() {
        
        GCController.shouldMonitorBackgroundEvents = true
        
        Controller.is_controller = GCController.controllers().count
    
        for controller in GCController.controllers() {
            
            controller.extendedGamepad?.valueChangedHandler = {
                (controller: GCExtendedGamepad, element: GCControllerElement) in
                
                Controller.leftThumbstick_x = controller.leftThumbstick.xAxis.value
                Controller.leftThumbstick_y = controller.leftThumbstick.yAxis.value
                Controller.rightThumbstick_x = controller.rightThumbstick.xAxis.value
                Controller.rightThumbstick_y = controller.rightThumbstick.yAxis.value
            }
        }
    }
    @objc func disconnectController() {
        Controller.is_controller = GCController.controllers().count
    }
}

