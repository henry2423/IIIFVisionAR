//
//  RotationSystem.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import SwiftUI
import RealityKit

/// Rotation information for an entity.
struct RotationComponent: Component {
    var speed: Float
    var axis: SIMD3<Float>
    var targetAngle: Float
    var onCompleted: () -> Void

    init(speed: Float = 3.0, targetAngle: Float = .pi, axis: SIMD3<Float> = [0, 0, 1], onCompleted: @escaping () -> Void) {
        self.speed = speed
        self.targetAngle = targetAngle
        self.axis = axis
        self.onCompleted = onCompleted
    }
}

/// A system that rotates entities with a rotation component.
struct RotationSystem: System {
    static let query = EntityQuery(where: .has(RotationComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, when: .rendering) {
            guard let component: RotationComponent = entity.components[RotationComponent.self] else { continue }

            guard abs(entity.orientation.angle.distance(to: component.targetAngle)) > 0.05 else {
                component.onCompleted()
                entity.components.remove(RotationComponent.self)
                return
            }

            entity.setOrientation(.init(angle: component.speed * Float(context.deltaTime), axis: component.axis), relativeTo: entity)
        }
    }
}
