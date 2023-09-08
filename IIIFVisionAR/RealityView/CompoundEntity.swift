//
//  CompoundEntity.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import RealityKit
import SwiftUI

final class CompoundEntity: Entity {

    required init(width: Float, height: Float, imageURLPairs: [(URL?, URL?)]) {
        self.imageWidth = width
        self.imageHeight = height
        self.imageURLPairs = imageURLPairs

        super.init()

        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
        self.components.set(InputTargetComponent())
        observeNotification()
    }

    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .rotationFinished, object: nil)
    }

    func loadInitialPages() async throws {
        currentRightPageIndex = 1

        // Load the left side (ideally nil images)
        try? await addPreviousPage(frontImageURL: imageURLPairs[currentRightPageIndex - 1].0,
                                   backImageURL: imageURLPairs[currentRightPageIndex - 1].1, 
                                   pageIndex: 0)

        // Load the right side
        try? await addNextPage(frontImageURL: imageURLPairs[currentRightPageIndex].0,
                               backImageURL: imageURLPairs[currentRightPageIndex].1,
                               pageIndex: 1)
    }

    @objc func cleanupNonVisibleEntities(_ notification: Notification) {
        turnPageQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            // Check for current pageIndex
            let pageIndex = self.currentRightPageIndex

            // Check if there're page in rotating, then skip the clean up process
            for (_, entity) in self.pageIndexEntityDict {
                if entity.components.has(RotationComponent.self) {
                    return
                }
            }

            // Remove extra page if needed if it's not presenting
            for (key, entity) in self.pageIndexEntityDict {
                if key != pageIndex && key != pageIndex - 1 {
                    self.pageIndexEntityDict.removeValue(forKey: key)
                    self.removeChild(entity)
                }
            }
        }
    }

    func turnToNextPage(_ value: EntityTargetValue<DragGesture.Value>) {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            // Don't turn when reaching the end of the pages
            guard self.currentRightPageIndex < self.imageURLPairs.count - 1 else {
                return
            }

            let asyncSemaphore = DispatchSemaphore(value: 0)

            Task {
                // Build the next page first
                try? await self.addNextPage(frontImageURL: self.imageURLPairs[self.currentRightPageIndex + 1].0,
                                            backImageURL: self.imageURLPairs[self.currentRightPageIndex + 1].1,
                                            pageIndex: self.currentRightPageIndex + 1)

                // Turn the right page
                let indexToBeTurned = self.currentRightPageIndex
                guard let entityToBeTurned = self.pageIndexEntityDict[indexToBeTurned] else {
                    return
                }

                // Add the rotationComponent to allow page rotation
                guard !entityToBeTurned.components.has(RotationComponent.self) else {
                    return
                }

                // Rotate to the targetAngle
                let rotationComponent = RotationComponent(targetAngle: .pi - Float(self.currentRightPageIndex) * 0.015, axis: [0, 0, 1])

                entityToBeTurned.components.set(rotationComponent)

                // Update the currenRightPageIndex
                self.currentRightPageIndex += 1

                asyncSemaphore.signal()
            }

            // Wait until the task finished
            asyncSemaphore.wait()
        }
    }

    func turnToPreviousPage(_ value: EntityTargetValue<DragGesture.Value>) {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            // Don't turn when reaching the start of the pages
            guard self.currentRightPageIndex > 1 else {
                return
            }

            let asyncSemaphore = DispatchSemaphore(value: 0)

            Task {
                // Build the previous page first
                try? await self.addPreviousPage(frontImageURL: self.imageURLPairs[self.currentRightPageIndex - 2].0,
                                                backImageURL: self.imageURLPairs[self.currentRightPageIndex - 2].1,
                                                pageIndex: self.currentRightPageIndex - 2)

                // Turn the left page
                let indexToBeTurned = self.currentRightPageIndex - 1
                guard let entityToBeTurned = self.pageIndexEntityDict[indexToBeTurned] else {
                    return
                }

                // Add the rotationComponent to allow page rotation
                guard !entityToBeTurned.components.has(RotationComponent.self) else {
                    return
                }

                // Rotate to the targetAngle
                let rotationComponent = RotationComponent(targetAngle: 0 + Float(self.currentRightPageIndex) * 0.015, axis: [0, 0, -1])

                entityToBeTurned.components.set(rotationComponent)

                // Update the currenRightPageIndex
                self.currentRightPageIndex -= 1

                asyncSemaphore.signal()
            }

            // Wait until the task finished
            asyncSemaphore.wait()
        }
    }

    private func addNextPage(frontImageURL: URL?, backImageURL: URL?, pageIndex: Int) async throws {
        // Skip building page if it existed
        guard pageIndexEntityDict[pageIndex] == nil else {
            return
        }

        let (frontPageEntity, backPageEntity) = try await buildPage(frontImageURL: frontImageURL, backImageURL: backImageURL)

        // Build rootEntity for two pages
        let pageRootEntity = Entity()
        pageRootEntity.transform.rotation = simd_quatf(angle: 0, axis: [0, 0, 1])
        pageRootEntity.addChild(frontPageEntity)
        pageRootEntity.addChild(backPageEntity)
        pageRootEntity.name = "\(pageIndex)"

        // Add front+back page into array
        pageIndexEntityDict[pageIndex] = pageRootEntity

        // Add to the Entity
        self.addChild(pageRootEntity)
        updateCollisionShape()
    }

    private func addPreviousPage(frontImageURL: URL?, backImageURL: URL?, pageIndex: Int) async throws {
        // Skip building page if it existed
        guard pageIndexEntityDict[pageIndex] == nil else {
            return
        }

        let (frontPageEntity, backPageEntity) = try await buildPage(frontImageURL: frontImageURL, backImageURL: backImageURL)

        // Build rootEntity for two pages
        let pageRootEntity = Entity()
        pageRootEntity.transform.rotation = simd_quatf(angle: 1 * Float.pi, axis: [0, 0, 1])
        pageRootEntity.addChild(frontPageEntity)
        pageRootEntity.addChild(backPageEntity)
        pageRootEntity.name = "\(pageIndex)"

        // Add front+back page into array
        pageIndexEntityDict[pageIndex] = pageRootEntity

        // Add to the Entity
        self.addChild(pageRootEntity)
        updateCollisionShape()
    }

    private func observeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(cleanupNonVisibleEntities(_:)),
                                               name: .rotationFinished,
                                               object: nil)
    }

    private func updateCollisionShape() {
        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components[CollisionComponent.self]?.shapes = [.generateBox(size: bounds)]
    }

    private func buildPage(frontImageURL: URL?, backImageURL: URL?) async throws -> (ModelEntity, ModelEntity) {
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

        return (frontPageEntity, backPageEntity)
    }

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
    private var pageIndexEntityDict = [Int: Entity]()  // [PageIndex: Entity]
    private let imageWidth: Float
    private let imageHeight: Float
    private let imageURLPairs: [(URL?, URL?)]
    private var currentRightPageIndex = 1
    private var notificationsObserveTask: Task<Void, Never>?
    private let turnPageQueue = DispatchQueue(label: "IIIFVisionAR.turnPageQueue")
}

// MARK: - Rotation and Drag Gesture

extension CompoundEntity {
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
        let delta = simd_quatf(angle: -Float(value.rotation.radians), axis: [0, 1, 0])
        self.transform.rotation = sourceRotation * delta
    }

    func handleRotationGestureEnded() {
        sourceRotation = nil
    }
}
