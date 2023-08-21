//
//  InteractiveObject.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import RealityKit
import SwiftUI

enum ImageEntityGenerator {
    @MainActor
    static func singleImagePlane(image_url: URL, width: Float, height: Float) async throws -> ModelEntity {
        let planeMesh = MeshResource.generatePlane(width: width, depth: height)
        var material = PhysicallyBasedMaterial()
        let resource = try await TextureResource(contentsOf: image_url)
        material.baseColor.texture = .init(resource)

        return ModelEntity(mesh: planeMesh, materials: [material])
    }
}

struct InteractiveObject {
    let entity: ModelEntity

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?

    init(entity: ModelEntity) {
        self.entity = entity

        let bounds = entity.model!.mesh.bounds.extents
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
        entity.components.set(HoverEffectComponent())
        entity.components.set(InputTargetComponent())
    }

    mutating func handleDragGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        let sourcePosition = sourcePosition ?? entity.position
        self.sourcePosition = sourcePosition
        let delta = value.convert(value.translation3D, from: .local, to: entity.parent!)
        // Only allow the object to be moved along the X- and Z-axis.
        entity.position = sourcePosition + SIMD3(delta.x, 0, delta.z)
    }

    mutating func handleDragGestureEnded() {
        sourcePosition = nil
    }

    mutating func handleRotationGesture(_ value: EntityTargetValue<RotateGesture.Value>) {
        let sourceRotation = sourceRotation ?? entity.transform.rotation
        self.sourceRotation = sourceRotation
        let delta = simd_quatf(angle: Float(value.rotation.radians), axis: [0, 1, 0])
        entity.transform.rotation = sourceRotation * delta
    }

    mutating func handleRotationGestureEnded() {
        sourceRotation = nil
    }
}
