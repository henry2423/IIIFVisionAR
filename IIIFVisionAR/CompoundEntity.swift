//
//  CompoundEntity.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import RealityKit
import SwiftUI

final class CompoundEntity: Entity {
    required init(width: Float, height: Float) {
        self.imageWidth = width
        self.imageHeight = height

        super.init()

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

    func addNextPage(frontImageURL: URL?, backImageURL: URL?) async throws {
        // Set front page
        var frontMaterial = UnlitMaterial(color: .white)

        if let frontImageURL {
            let resource = try await TextureResource(contentsOf: frontImageURL)
            frontMaterial.color.texture = .init(resource)
        }
        else {
            frontMaterial.color.tint = .clear
        }

        let frontPageEntity = ModelEntity(mesh: .generatePlane(width: imageWidth, depth: imageHeight), materials: [frontMaterial])
        frontPageEntity.position = [imageWidth / 2, 0, 0]

        // Set back page
        var backMaterial = UnlitMaterial(color: .white)

        if let backImageURL {
            let resource = try await TextureResource(contentsOf: backImageURL)
            backMaterial.color.texture = .init(resource)
        }
        else {
            backMaterial.color.tint = .clear
        }

        let backPageEntity = ModelEntity(mesh: .generatePlane(width: imageWidth, depth: imageHeight), materials: [backMaterial])
        backPageEntity.transform.rotation = simd_quatf(angle: -1 * Float.pi, axis: [0, 0, 1])
        backPageEntity.position = [imageWidth / 2, 0, 0]

        // Build anchor for two pages

        let pageAnchorEntity = AnchorEntity()
        pageAnchorEntity.transform.rotation = simd_quatf(angle: 0, axis: [0, 0, 1])
        pageAnchorEntity.addChild(frontPageEntity)
        pageAnchorEntity.addChild(backPageEntity)

        // Add front+back page into array
        self.pageEntities.append(pageAnchorEntity)

        // Add to the Entity
        self.addChild(pageAnchorEntity)
        updateCollisionShape()
    }

    func addPreviousPage(frontImageURL: URL?, backImageURL: URL?) async throws {
        // Set front page
        var frontMaterial = UnlitMaterial(color: .white)

        if let frontImageURL {
            let resource = try await TextureResource(contentsOf: frontImageURL)
            frontMaterial.color.texture = .init(resource)
        }
        else {
            frontMaterial.color.tint = .clear
        }

        let frontPageEntity = ModelEntity(mesh: .generatePlane(width: imageWidth, depth: imageHeight), materials: [frontMaterial])
        frontPageEntity.position = [imageWidth / 2, 0, 0]

        // Set back page
        var backMaterial = UnlitMaterial(color: .white)

        if let backImageURL {
            let resource = try await TextureResource(contentsOf: backImageURL)
            backMaterial.color.texture = .init(resource)
        }
        else {
            backMaterial.color.tint = .clear
        }

        let backPageEntity = ModelEntity(mesh: .generatePlane(width: imageWidth, depth: imageHeight), materials: [backMaterial])
        backPageEntity.transform.rotation = simd_quatf(angle: -1 * Float.pi, axis: [0, 0, 1])
        backPageEntity.position = [imageWidth / 2, 0, 0]

        // Build anchor for two pages

        let pageAnchorEntity = AnchorEntity()
        pageAnchorEntity.transform.rotation = simd_quatf(angle: 1 * Float.pi, axis: [0, 0, 1])

        pageAnchorEntity.addChild(frontPageEntity)
        pageAnchorEntity.addChild(backPageEntity)

        // Add front+back page into array
        self.pageEntities.insert(pageAnchorEntity, at: 0)

        // Add to the Entity
        self.addChild(pageAnchorEntity)
        updateCollisionShape()
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

    func turnToNextPage(_ value: EntityTargetValue<DragGesture.Value>) {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            let indexToBeTurned = pageEntities.count - 2    // The middle page is the one to be turn

            guard !self.pageEntities[indexToBeTurned].components.has(RotationComponent.self) else {
                return
            }

            let semaphore = DispatchSemaphore(value: 0)

            let rotationComponent = RotationComponent(targetAngle: .pi, axis: [0, 0, 1]) { [weak self] in
                guard let self else { return }

                if self.pageEntities.count > 2 {
                    let entity = self.pageEntities.removeFirst()
                    self.removeChild(entity)
                }

                semaphore.signal()
            }

            self.pageEntities[indexToBeTurned].components.set(rotationComponent)
            semaphore.wait()
        }
    }

    func turnToPreviousPage(_ value: EntityTargetValue<DragGesture.Value>) {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            let indexToBeTurned = pageEntities.count - 2    // The middle page is the one to be turn

            guard !self.pageEntities[indexToBeTurned].components.has(RotationComponent.self) else {
                return
            }

            let semaphore = DispatchSemaphore(value: 0)

            let rotationComponent = RotationComponent(targetAngle: 0, axis: [0, 0, -1]) { [weak self] in
                guard let self else { return }

                if self.pageEntities.count > 2 {
                    let entity = self.pageEntities.removeLast()
                    self.removeChild(entity)
                }

                semaphore.signal()
            }

            self.pageEntities[indexToBeTurned].components.set(rotationComponent)
            semaphore.wait()
        }
    }

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
    private var pageEntities = [AnchorEntity]()
    private let imageWidth: Float
    private let imageHeight: Float
    private let turnPageQueue = DispatchQueue(label: "IIIFVisionAR.turnPageQueue")
}
