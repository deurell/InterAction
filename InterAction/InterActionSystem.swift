import RealityKit
import Foundation

struct InterActionComponent: Component {}

class InterActionSystem : RealityKit.System
{
    static let InterActionComponentQuery = EntityQuery(where: .has(InterActionComponent.self))
    var time: Double = 0
    
    required init(scene: RealityKit.Scene) {
    }
    
    func update(context: SceneUpdateContext) {
        self.time += context.deltaTime
        let camera = context.scene.performQuery(CameraComponent.query).map { $0 }.first
        let crosshair = context.scene.performQuery(InterActionSystem.InterActionComponentQuery).map { $0 }.first
        updateCrosshair(camera: camera, crosshair: crosshair)
    }
    
    func updateCrosshair(camera: Entity?, crosshair: Entity?) {
        guard let camera = camera,
              let crosshair = crosshair
        else { return }
        
        let cameraForward = normalize(simd_float3(-camera.transform.matrix.columns.2.x, -camera.transform.matrix.columns.2.y, -camera.transform.matrix.columns.2.z))
        let crosshairPosition = camera.position(relativeTo: camera.parent)
        crosshair.position = crosshairPosition + cameraForward * 0.1
        
    }
}
