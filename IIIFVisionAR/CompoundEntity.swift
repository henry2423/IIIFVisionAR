//
//  CompoundEntity.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import RealityKit
import SwiftUI

final class CompoundEntity: Entity {
    var leftFrontModelEntiy: ModelEntity
    var rightFrontModelEntiy: ModelEntity

    required init(width: Float, height: Float) {
        let emptyMaterial = UnlitMaterial()
        leftFrontModelEntiy = ModelEntity(mesh: .generatePlane(width: width, depth: height), materials: [emptyMaterial])
        leftFrontModelEntiy.position = [(-1 * width / 2), 0.001, 0]

        rightFrontModelEntiy = ModelEntity(mesh: .generatePlane(width: width, depth: height), materials: [emptyMaterial])
        rightFrontModelEntiy.position = [width / 2, 0.001, 0]

        let leftFrontBounds = leftFrontModelEntiy.model!.mesh.bounds.extents
        leftFrontModelEntiy.components.set(CollisionComponent(shapes: [.generateBox(size: leftFrontBounds)]))
        leftFrontModelEntiy.components.set(HoverEffectComponent())
        leftFrontModelEntiy.components.set(InputTargetComponent())

        let rightFrontBounds = rightFrontModelEntiy.model!.mesh.bounds.extents
        rightFrontModelEntiy.components.set(CollisionComponent(shapes: [.generateBox(size: rightFrontBounds)]))
        rightFrontModelEntiy.components.set(HoverEffectComponent())
        rightFrontModelEntiy.components.set(InputTargetComponent())

        super.init()

        self.addChild(leftFrontModelEntiy)
        self.addChild(rightFrontModelEntiy)
    }
    
    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    func setImages(leftFrontImageURL: URL?, rightFrontImageURL: URL?) async throws {
        var leftFrontMaterial = UnlitMaterial(color: .white)

        //make the new materials: 2 at a time
        if let leftFrontImageURL {
            let resource = try await TextureResource(contentsOf: leftFrontImageURL)
            leftFrontMaterial.color.texture = .init(resource)
        }
        else {
            leftFrontMaterial.color.tint = .clear
        }

        leftFrontModelEntiy.model?.materials[0] = leftFrontMaterial

        var rightFrontMaterial = UnlitMaterial(color: .white)

        //make the new materials: 2 at a time
        if let rightFrontImageURL {
            let resource = try await TextureResource(contentsOf: rightFrontImageURL)
            rightFrontMaterial.color.texture = .init(resource)
        }
        else {
            rightFrontMaterial.color.tint = .clear
        }

        rightFrontModelEntiy.model?.materials[0] = rightFrontMaterial
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

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
}
