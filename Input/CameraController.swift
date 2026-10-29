import simd

class CameraController {

    var movementSpeed: Float = 5.0
    var mouseSensitivity: Float = 0.003

    func update(camera: Camera, input: InputManager, deltaTime: Float) {
        
        //Rotation
        let mouseDelta = input.consumeMouseMovement()

        camera.yaw -= mouseDelta.x * mouseSensitivity
        camera.pitch += mouseDelta.y * mouseSensitivity

        let pitchLimit: Float = .pi / 2 - 0.01

        camera.pitch = max(-pitchLimit, min(camera.pitch, pitchLimit))

        //Movement
        let forward = SIMD3<Float>(-sin(camera.yaw), 0, -cos(camera.yaw))

        let right = SIMD3<Float>(cos(camera.yaw), 0, -sin(camera.yaw))

        var movement = SIMD3<Float>(0, 0, 0)

        if input.isPressed(.W_key) {
            movement += forward
        }

        if input.isPressed(.S_key) {
            movement -= forward
        }

        if input.isPressed(.D_key) {
            movement += right
        }

        if input.isPressed(.A_key) {
            movement -= right
        }

        if input.isPressed(.Space_key) {
            movement.y += 1
        }
        
        if input.isPressed(.Shift_key) {
            movement.y -= 1
        }

        if simd_length_squared(movement) > 0 {
            movement = simd_normalize(movement)
            camera.position += movement * movementSpeed * deltaTime
        }
    }
}
