import Foundation
import RealityKit
import ARKit
import SwiftUI

class PlayView: ARView, ARSessionDelegate {

    var arView: ARView { return self }
    var anchor: AnchorEntity!
    var camera: AnchorEntity?
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("not implemented")
    }
    
    func setup() {
        arView.cameraMode = .ar
        setupScene()
        setupARSession()
        setupCameraBuddy()
        setupPhysicsOrigin()
    }
    
    private func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection.insert(.horizontal)
        session.run(configuration)
        session.delegate = self
    }
    
    private func setupScene() {
        anchor = AnchorEntity(.plane(.horizontal, classification: .any,
                                         minimumBounds: [0.5, 0.5]))
        scene.anchors.append(anchor)
        
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = 4000
        directionalLight.light.isRealWorldProxy = true
        directionalLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 10,
                  depthBias: 5.0)
        directionalLight.position = [1,8,5]
        directionalLight.look(at: [-2,-2,-4], from: directionalLight.position, relativeTo: nil)
        anchor.addChild(directionalLight)
        
        let planeSize:simd_float3 = [0.5, 0.5, 0.05]
        let planeMesh: MeshResource = .generateBox(size: planeSize)
        let planeMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.2), roughness: 0.5, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        planeEntity.position = [0, 0, 0]
        planeEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: [1,0,0])
        planeEntity.collision = CollisionComponent(shapes: [.generateBox(size: planeSize)])
        planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        anchor.addChild(planeEntity)
        
        let crosshairMesh: MeshResource = .generateSphere(radius: 0.001)
        let crosshairMaterial = SimpleMaterial(color: .green.withAlphaComponent(0.8), roughness: 0.5, isMetallic: false)
        let crosshairEntity = ModelEntity(mesh: crosshairMesh, materials: [crosshairMaterial])
        crosshairEntity.components.set(InterActionComponent())
        anchor.addChild(crosshairEntity)
    }
    
    private func setupCameraBuddy() {
        let camera = AnchorEntity(world: SIMD3<Float>())
        self.camera = camera
        camera.components.set(CameraComponent())
        anchor.addChild(camera)
    }
    
    private func setupPhysicsOrigin() {
        let physicsOrigin = Entity()
        physicsOrigin.scale = .init(repeating: 1.0)
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(physicsOrigin)
        scene.addAnchor(anchor)
        self.physicsOrigin = physicsOrigin
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        camera?.transform = .init(matrix: frame.camera.transform)
    }
}

struct CameraComponent: Component {
    static let query = EntityQuery(where: .has(CameraComponent.self))
}
