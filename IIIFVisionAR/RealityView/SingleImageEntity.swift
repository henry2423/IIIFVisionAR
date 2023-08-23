//
//  InteractiveObject.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import RealityKit
import SwiftUI

final class SingleImageEntity: Entity {

    required init(width: Float, height: Float) {
        self.imageWidth = width
        self.imageHeight = height

        let planeMesh = MeshResource.generatePlane(width: width, depth: height)
        self.imageModelEntity = ModelEntity(mesh: planeMesh, materials: [])

        super.init()

        self.addChild(imageModelEntity)

        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
        self.components.set(InputTargetComponent())
    }

    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    func updateCollisionShape() {
        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components[CollisionComponent.self]?.shapes = [.generateBox(size: bounds)]
    }

    func setImage(imageURL: URL) async throws {
        var material = PhysicallyBasedMaterial()
        let resource = try await TextureResource(contentsOf: imageURL)
        material.baseColor.texture = .init(resource)
        imageModelEntity.model?.materials = [material]
    }

    func handleDragGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        let sourcePosition = sourcePosition ?? self.position
        self.sourcePosition = sourcePosition
        let delta = value.convert(value.translation3D, from: .local, to: self.parent!)
        // Only allow the object to be moved along the X- and Z-axis.
        self.position = sourcePosition + SIMD3(delta.x, 0, delta.z)
    }

    func handleDragGestureEnded() {
        sourcePosition = nil
    }

    func handleRotationGesture(_ value: EntityTargetValue<RotateGesture.Value>) {
        let sourceRotation = sourceRotation ?? self.transform.rotation
        self.sourceRotation = sourceRotation
        let delta = simd_quatf(angle: Float(value.rotation.radians), axis: [0, 1, 0])
        self.transform.rotation = sourceRotation * delta
    }

    func handleRotationGestureEnded() {
        sourceRotation = nil
    }

    private let imageModelEntity: ModelEntity
    private let imageWidth: Float
    private let imageHeight: Float
    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
}
