//
//  Dice.swift
//  Dice
//
//  Created by Mikael Deurell on 2022-09-07.
//

import RealityKit
import Foundation

extension PlayView
{
    func addDice(numberToSpawn: Int) {
        var dice = [Entity]()
        
        let diceEntity = createDice()
        dice.append(diceEntity)
        
        for _ in 1..<numberToSpawn {
            let clone = diceEntity.clone(recursive: true)
            installTranslateGesureRecognizer(for: clone)
            dice.append(clone)
        }
        
        var spawnOrder: TimeInterval = 0
        let spawnDelay: TimeInterval = 0.4
        let spawnRadius: Float = 0.1
        for die in dice {
            spawnOrder += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + (spawnDelay * spawnOrder)) {
                self.anchor.addChild(die)
                let spawnPoint = simd_float3.random(in: Float(-spawnRadius)..<Float(spawnRadius))
                die.transform.translation = [spawnPoint.x, die.transform.translation.y, spawnPoint.z]
            }
        }
    }
    
    func createDice() -> ModelEntity {
        let diceEntity = try! Entity.loadModel(named: "DiceWhite")
        diceEntity.position = [0, 0.2, 0]
        let size = diceEntity.visualBounds(relativeTo: diceEntity).extents
        let boxShape = ShapeResource.generateBox(size: size)
        diceEntity.collision = CollisionComponent(shapes: [boxShape])
        let physicsMaterial = PhysicsMaterialResource.generate(friction: 1.5, restitution: 0.4)
        diceEntity.physicsBody = PhysicsBodyComponent(massProperties: PhysicsMassProperties(shape: boxShape, mass: 0.5),
                                                        material: physicsMaterial,
                                                      mode: .dynamic)
        diceEntity.physicsMotion = PhysicsMotionComponent()
        diceEntity.components[InterActionComponent.self] = InterActionComponent()
        installTranslateGesureRecognizer(for: diceEntity)
        return diceEntity
    }
    
    func installTranslateGesureRecognizer(for entity: Entity){
        guard let entity = entity as? HasCollision else { return }
        let gestureReconizers = self.installGestures([.translation], for: entity)
        gestureReconizers.first!.addTarget(self, action: #selector(translateDice))
    }
    
    @objc private func translateDice(_ recognizer: EntityTranslationGestureRecognizer) {
        let dice = recognizer.entity as! HasPhysics
        
        if recognizer.state == .began {
            dice.physicsBody?.mode = .kinematic
            dice.components[DiceLeaderComponent.self] = DiceLeaderComponent()
            return
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            if recognizer.state == .ended {
                dice.addForce([0,4,0], relativeTo: nil)
                dice.addTorque([.random(in: 0...0.5),0,0], relativeTo: nil)
                scene.performQuery(InterActionSystem.diceComponentQuery).forEach { entity in
                    let vectorToLeader = dice.position - entity.position
                    let force:Float = 8.0
                    if let entity = entity as? HasPhysicsBody {
                        entity.addForce(vectorToLeader*force, relativeTo: entity.parent)
                    }
                }
                dice.components.remove(DiceLeaderComponent.self)
                dice.physicsBody?.mode = .dynamic
            }
            return
        }
        
        let velocity = recognizer.velocity(in: dice)
        print("TranslationGestureRecognizer_velocity: \(velocity)")
        dice.physicsMotion?.linearVelocity = [velocity.x, 0, velocity.z]
    }
}
