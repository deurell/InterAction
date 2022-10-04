import RealityKit
import Foundation

class InterActionSystem : RealityKit.System
{
    var time: Double = 0
    
    required init(scene: RealityKit.Scene) {
    }
    
    func update(context: SceneUpdateContext) {
        self.time += context.deltaTime
        guard let camera = context.scene.performQuery(CameraComponent.query).map({ $0 }).first,
        let crosshair = context.scene.performQuery(CrosshairComponent.query).map({ $0 }).first else { return }
        updateCrosshair(camera: camera, crosshair: crosshair)
        
        if let grabbedEntity = context.scene.performQuery(GrabbedComponent.query).map({ $0 }).first {
            guard let component = grabbedEntity.components[GrabbedComponent.self] as? GrabbedComponent else { return }
            let moveVector = camera.transform.translation - component.startCameraPosition
            let panOffsetScale: Float = 0.0004
            grabbedEntity.transform.translation = component.startEntityPosition + moveVector + component.panOffset * panOffsetScale
            grabbedEntity.components.set(component)
            // todo: needs to adjust to camera position relative to piece, for now just do forward facing.
            grabbedEntity.transform.rotation = simd_quatf(angle: .pi/2, axis: [0,0,1]) * camera.transform.rotation
        }
    }
    
    func updateCrosshair(camera: Entity?, crosshair: Entity?) {
        guard let camera = camera,
              let crosshair = crosshair
        else { return }
        
        let cameraForward = camera.transform.matrix.forward
        let cameraPosition = camera.position(relativeTo: camera.parent)
        crosshair.position = cameraPosition + cameraForward * 0.1
    }
}

extension float4x4 {
    var forward: SIMD3<Float> {
        normalize(SIMD3<Float>(-columns.2.x, -columns.2.y, -columns.2.z))
    }
}
