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
    var centerAnchorEntity: AnchorEntity

    required init(width: Float, height: Float) {
        let emptyMaterial = UnlitMaterial()
        leftFrontModelEntiy = ModelEntity(mesh: .generatePlane(width: width, depth: height), materials: [emptyMaterial])
        leftFrontModelEntiy.position = [(-1 * width / 2), 0, 0]

        rightFrontModelEntiy = ModelEntity(mesh: .generatePlane(width: width, depth: height), materials: [emptyMaterial])
        rightFrontModelEntiy.position = [width / 2, 0, 0]

        centerAnchorEntity = AnchorEntity()
        centerAnchorEntity.addChild(rightFrontModelEntiy)

        super.init()

        self.addChild(leftFrontModelEntiy)
        self.addChild(centerAnchorEntity)

        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
        self.components.set(InputTargetComponent())
    }
    
    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    func setImages(leftFrontImageURL: URL?, rightFrontImageURL: URL?) async throws {
        var leftFrontMaterial = UnlitMaterial(color: .white)

        if let leftFrontImageURL {
            let resource = try await TextureResource(contentsOf: leftFrontImageURL)
            leftFrontMaterial.color.texture = .init(resource)
        }
        else {
            leftFrontMaterial.color.tint = .clear
        }

        leftFrontModelEntiy.model?.materials[0] = leftFrontMaterial

        var rightFrontMaterial = UnlitMaterial(color: .white)

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
        self.centerAnchorEntity.transform.rotation = sourceRotation * delta
    }

    func handleRotationGestureEnded() {
        sourceRotation = nil
    }

    func handleSwipLeftGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        Task {
//            try! await setImages(leftFrontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!, rightFrontImageURL: nil)
            guard centerAnchorEntity.components[RotationComponent.self] == nil else {
                return
            }
            centerAnchorEntity.components.set(RotationComponent())
        }
    }

    func handleSwipRightGesture(_ value: EntityTargetValue<DragGesture.Value>) {
//        Task {
//            try! await setImages(leftFrontImageURL: nil, rightFrontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!)
//        }
    }

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
}
