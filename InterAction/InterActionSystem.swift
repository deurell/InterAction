import RealityKit
import Foundation

class InterActionSystem : RealityKit.System
{
    var time: Double = 0
    
    required init(scene: RealityKit.Scene) {
    }
    
    func update(context: SceneUpdateContext) {
        self.time += context.deltaTime
        guard
            let camera = context.scene.performQuery(CameraComponent.query).map({ $0 }).first,
            let crosshair = context.scene.performQuery(CrosshairComponent.query).map({ $0 }).first
        else { return }
                
        if let grabbedEntity = context.scene.performQuery(GrabbedComponent.query).map({ $0 }).first {
            guard let component = grabbedEntity.components[GrabbedComponent.self] as? GrabbedComponent else { return }
            let moveVector = camera.transform.translation - component.startCameraPosition
            let panOffsetScale: Float = 0.0004
            let offsetVector = component.panOffset * panOffsetScale

            let cameraForwardVector = camera.transform.matrix.forward
            let cameraAngle = atan2(cameraForwardVector.x, cameraForwardVector.z)
            let adjustmentRotation = simd_quatf(angle: cameraAngle - Float.pi, axis: [0,1,0])
            let cameraAdjustedOffsetVector = adjustmentRotation.act(offsetVector)

            grabbedEntity.transform.translation = component.startEntityPosition + moveVector + cameraAdjustedOffsetVector
            grabbedEntity.components.set(component)
            
            let perpendicularCameraForward = simd_cross([0,1,0], cameraForwardVector)

            grabbedEntity.transform.rotation = simd_quatf(angle: -.pi/3, axis: perpendicularCameraForward) *  simd_quatf(angle: -.pi/2, axis: cameraForwardVector) * camera.transform.rotation
            
            updateCrosshair(camera: camera, crosshair: crosshair, entity: grabbedEntity)
        } else {
            updateCrosshair(camera: camera, crosshair: crosshair)
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
    
    func updateCrosshair(camera: Entity?, crosshair: Entity?, entity: Entity?) {
        guard let camera = camera,
              let crosshair = crosshair,
              let entity = entity
        else { return }
        
        let cameraDirectionToEntity = simd_normalize(entity.position(relativeTo: nil) - camera.position(relativeTo: nil))
        crosshair.position = camera.position(relativeTo: camera.parent) + cameraDirectionToEntity * 0.1
    }
}

extension float4x4 {
    var forward: SIMD3<Float> {
        normalize(SIMD3<Float>(-columns.2.x, -columns.2.y, -columns.2.z))
    }
}
