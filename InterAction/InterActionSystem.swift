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
            let panOffsetScale: Float = 0.0006
            let offsetVector = component.panTranslation * panOffsetScale
            
            let cameraForwardVector = camera.transform.matrix.forward
            let cameraAngle = atan2(cameraForwardVector.x, cameraForwardVector.z)
            let adjustmentRotation = simd_quatf(angle: cameraAngle - Float.pi, axis: [0,1,0])
            let cameraAdjustedOffsetVector = adjustmentRotation.act(offsetVector)
            
            grabbedEntity.transform.translation = component.startEntityPosition + moveVector + cameraAdjustedOffsetVector
            grabbedEntity.components.set(component)
            
            grabbedEntity.transform.rotation =  camera.transform.rotation  *  simd_quatf(angle: Float.pi/4, axis: [0,1,0]) * simd_quatf(angle: Float.pi/2, axis: [0,0,1])
            
            
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
        let cameraWorldPosition = camera.position(relativeTo: nil)
        crosshair.setPosition(cameraWorldPosition + cameraForward * 0.1, relativeTo: nil)
    }
    
    func updateCrosshair(camera: Entity?, crosshair: Entity?, entity: Entity?) {
        guard let camera = camera,
              let crosshair = crosshair,
              let entity = entity
        else { return }
        
        let cameraDirectionToEntity = simd_normalize(entity.position(relativeTo: nil) - camera.position(relativeTo: nil))
        let cameraWorldPosition = camera.position(relativeTo: nil)
        crosshair.setPosition(cameraWorldPosition  + cameraDirectionToEntity * 0.1, relativeTo: nil)
    }
}


extension float4x4 {
    var forward: SIMD3<Float> {
        normalize(SIMD3<Float>(-columns.2.x, -columns.2.y, -columns.2.z))
    }
    
    var right: SIMD3<Float> {
        normalize(SIMD3<Float>(columns.0.x, columns.0.y, columns.0.z))
    }
}
