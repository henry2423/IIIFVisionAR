//
//  CompoundEntity.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import RealityKit
import SwiftUI

final class CompoundEntity: Entity {
    var pageEntities = [AnchorEntity]()
    var imageURLs = [URL]()

    required init(width: Float, height: Float, imageURLs: [URL]) {
        self.imageURLs = imageURLs

        let emptyMaterial = UnlitMaterial()

        let frontPageEntity = ModelEntity(mesh: .generatePlane(width: width, depth: height), materials: [emptyMaterial])
        frontPageEntity.position = [width / 2, 0, 0]
        frontPageEntity.name = "frontPageEntity"

        let backPageEntity = ModelEntity(mesh: .generatePlane(width: width, depth: height), materials: [emptyMaterial])
        backPageEntity.transform.rotation = simd_quatf(angle: -1 * Float.pi, axis: [0, 0, 1])
        backPageEntity.position = [width / 2, 0, 0]
        backPageEntity.name = "backPageEntity"

        let pageAnchorEntity = AnchorEntity()
        pageAnchorEntity.addChild(frontPageEntity)
        pageAnchorEntity.addChild(backPageEntity)

        super.init()

        self.pageEntities.append(pageAnchorEntity)
        self.addChild(pageAnchorEntity)

        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
        self.components.set(InputTargetComponent())
    }
    
    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    func setInitialPage(frontImageURL: URL?, backImageURL: URL?) async throws {
        guard let frontPageModelEntity = pageEntities[0].findEntity(named: "frontPageEntity") as? ModelEntity,
              let backPageModelEntity = pageEntities[0].findEntity(named: "backPageEntity") as? ModelEntity else {
            return
        }

        // Set front page
        var frontMaterial = UnlitMaterial(color: .white)

        if let frontImageURL {
            let resource = try await TextureResource(contentsOf: frontImageURL)
            frontMaterial.color.texture = .init(resource)
        }
        else {
            frontMaterial.color.tint = .clear
        }

        frontPageModelEntity.model?.materials[0] = frontMaterial

        // Set back page
        var backMaterial = UnlitMaterial(color: .white)

        if let backImageURL {
            let resource = try await TextureResource(contentsOf: backImageURL)
            backMaterial.color.texture = .init(resource)
        }
        else {
            backMaterial.color.tint = .clear
        }

        backPageModelEntity.model?.materials[0] = backMaterial
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
//        self.transform.rotation = sourceRotation * delta
        for entity in pageEntities {
            entity.transform.rotation = sourceRotation * delta
        }
    }

    func handleRotationGestureEnded() {
        sourceRotation = nil
    }

    func handleSwipLeftGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        Task {
            guard pageEntities.last!.components[RotationComponent.self] == nil else {
                return
            }
            pageEntities.last!.components.set(RotationComponent(axis: [0, 0, 1]))
        }
    }

    func handleSwipRightGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        Task {
            guard pageEntities.first!.components[RotationComponent.self] == nil else {
                return
            }
            pageEntities.first!.components.set(RotationComponent(targetAngle: 0, axis: [0, 0, -1]))
        }
    }

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
}
