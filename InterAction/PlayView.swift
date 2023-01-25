import Foundation
import RealityKit
import ARKit
import SwiftUI
import Combine

class PlayView: ARView, ARSessionDelegate {
    
    var arView: ARView { return self }
    var anchor: AnchorEntity!
    var camera: AnchorEntity?
    var sub: Cancellable?
    var initialized:Bool = false
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("not implemented")
    }
    
    func setup() {
        arView.cameraMode = .ar
        setupARSession()
        setupScene()
        setupCameraBuddy()
        setupPhysicsOrigin()
        setupGestures()
        
        scene.anchors.append(anchor)
        sub = arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self) {[weak self] event in
            guard let self = self else { fatalError() }
            self.initialized = true
        }
    }
    
    private func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection.insert(.horizontal)
        session.run(configuration)
        session.delegate = self
    }
    
    private func setupScene() {
        self.anchor = AnchorEntity(.plane(.horizontal, classification: .any,
                                          minimumBounds: [0.5, 0.5]))
        guard let anchor = self.anchor else {fatalError()}
        
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
                
        let crosshairMesh: MeshResource = .generateSphere(radius: 0.001)
        let crosshairMaterial = SimpleMaterial(color: .green.withAlphaComponent(0.8), roughness: 0.5, isMetallic: false)
        let crosshairEntity = ModelEntity(mesh: crosshairMesh, materials: [crosshairMaterial])
        crosshairEntity.components.set(CrosshairComponent())
        anchor.addChild(crosshairEntity)
        
        let pickupEntity = try! Entity.loadModel(named: "cup")
        pickupEntity.model?.materials.append(SimpleMaterial(color: .white, isMetallic: false))
        pickupEntity.position = [0, 0, 0]
        pickupEntity.scale = .init(repeating: 0.0005)
        let size = pickupEntity.visualBounds(relativeTo: pickupEntity).extents
        let boxShape = ShapeResource.generateBox(size: size)
        pickupEntity.collision = CollisionComponent(shapes: [boxShape])
        let physicsMaterial = PhysicsMaterialResource.generate(friction: 1.5, restitution: 0.4)
        pickupEntity.physicsBody = PhysicsBodyComponent(massProperties: PhysicsMassProperties(shape: boxShape, mass: 0.5),
                                                      material: physicsMaterial,
                                                      mode: .kinematic)
        pickupEntity.physicsMotion = PhysicsMotionComponent()
        pickupEntity.components.set(InterActionComponent())
        anchor.addChild(pickupEntity)
    }
    
    func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        pan.delaysTouchesBegan = false
        self.addGestureRecognizer(pan)
    }
    
    var startPanCameraPosition:simd_float3 = [0,0,0]
    var startPanEntityPosition:simd_float3 = [0,0,0]
    var panEntity: Entity?
    
    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        guard let camera = camera else { return }
        switch sender.state {
        case .began:
            let raycasts: [CollisionCastHit] = arView.scene.raycast(origin: camera.position, direction: camera.transform.matrix.forward, length: 10.0, query: .all, mask: .all, relativeTo: nil)
            guard let rayCast: CollisionCastHit = raycasts.first(where: {$0.entity.components.has(InterActionComponent.self)} ) else { break }
            panEntity = rayCast.entity
            startPanCameraPosition = camera.position
            startPanEntityPosition = panEntity!.position
            panEntity?.components.set(GrabbedComponent(startCameraPosition: startPanCameraPosition, startEntityPosition: startPanEntityPosition, panOffset: [0,0,0]))
        case .changed:
            guard var component = panEntity?.components[GrabbedComponent.self] as? GrabbedComponent else { break }
            component.startCameraPosition = startPanCameraPosition
            component.startEntityPosition = startPanEntityPosition
            let panOffset: simd_float3 = simd_float3(Float(sender.translation(in: self).x), 0, Float(sender.translation(in: self).y))
            component.panOffset = panOffset
            panEntity?.components.set(component)
        case .ended, .cancelled:
            panEntity?.components.remove(GrabbedComponent.self)
            panEntity = nil
        default:
            break
        }
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
        self.camera?.transform = .init(matrix: frame.camera.transform)
    }
}

struct InterActionComponent: Component {
    static let query = EntityQuery(where: .has(Self.self))
}

struct CameraComponent: Component {
    static let query = EntityQuery(where: .has(Self.self))
}

struct CrosshairComponent: Component {
    static let query = EntityQuery(where: .has(Self.self))
}

struct GrabbedComponent: Component {
    static let query = EntityQuery(where: .has(Self.self))
    var startCameraPosition: simd_float3
    var startEntityPosition: simd_float3
    var panOffset: simd_float3
}
