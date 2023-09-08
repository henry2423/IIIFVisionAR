//
//  CompoundEntity.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import RealityKit
import SwiftUI

actor PageTurnState {
    var currentRightPageIndex = 1

    func updateCurrentRightPageIndex(to newValue: Int) {
        currentRightPageIndex = newValue
    }

    func cachePageEntity(index: Int, entity: Entity) {
        pageIndexEntityDict[index] = entity
    }

    func removePageEntity(index: Int) {
        pageIndexEntityDict.removeValue(forKey: index)
    }

    func getPageEntity(index: Int) -> Entity? {
        pageIndexEntityDict[index]
    }

    func allPageIndexPairs() -> [Int: Entity] {
        pageIndexEntityDict
    }

    private var pageIndexEntityDict = [Int: Entity]()  // [PageIndex: Entity]
}

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
        await pageTurnState.updateCurrentRightPageIndex(to: 1)

        // Load the left side (ideally nil images)
        try? await addPreviousPage(frontImageURL: imageURLPairs[0].0,
                                   backImageURL: imageURLPairs[0].1,
                                   pageIndex: 0)

        // Load the right side
        try? await addNextPage(frontImageURL: imageURLPairs[1].0,
                               backImageURL: imageURLPairs[1].1,
                               pageIndex: 1)
    }

    @objc func cleanupNonVisibleEntities(_ notification: Notification) {
        turnPageQueue.async { [weak self] in
            guard let self else {
                return
            }

            Task {
                // Check for current pageIndex
                let pageIndex = await self.pageTurnState.currentRightPageIndex

                // Remove extra page if needed if it's not presenting
                let allPageIndexEntity = await self.pageTurnState.allPageIndexPairs()

                for (key, entity) in allPageIndexEntity {
                    if key != pageIndex && key != pageIndex - 1 {
                        await self.pageTurnState.removePageEntity(index: key)
                        self.removeChild(entity)
                    }
                }

                // Release the lock so next turn next/previous action can start
                self.turnPageSemaphore.signal()
            }
        }
    }

    func turnToNextPage(_ value: EntityTargetValue<DragGesture.Value>) {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            // Lock the pageTurn action to ensure one turn at a time
            turnPageSemaphore.wait()

            Task {
                let currentRightPageIndex = await self.pageTurnState.currentRightPageIndex

                // Don't turn when reaching the end of the pages
                guard currentRightPageIndex < self.imageURLPairs.count - 1 else {
                    self.turnPageSemaphore.signal()
                    return
                }

                // Build the next page first
                try? await self.addNextPage(frontImageURL: self.imageURLPairs[currentRightPageIndex + 1].0,
                                            backImageURL: self.imageURLPairs[currentRightPageIndex + 1].1,
                                            pageIndex: currentRightPageIndex + 1)

                // Turn the right page
                let indexToBeTurned = currentRightPageIndex
                guard let entityToBeTurned = await self.pageTurnState.getPageEntity(index: indexToBeTurned) else {
                    self.turnPageSemaphore.signal()
                    return
                }

                // Add the rotationComponent to allow page rotation
                guard !entityToBeTurned.components.has(RotationComponent.self) else {
                    self.turnPageSemaphore.signal()
                    return
                }

                // Rotate to the targetAngle
                let rotationComponent = RotationComponent(targetAngle: .pi - Float(currentRightPageIndex) * 0.015, axis: [0, 0, 1])

                entityToBeTurned.components.set(rotationComponent)

                // Update the currenRightPageIndex
                await self.pageTurnState.updateCurrentRightPageIndex(to: currentRightPageIndex + 1)
            }
        }
    }

    func turnToPreviousPage(_ value: EntityTargetValue<DragGesture.Value>) {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            // Lock the pageTurn action to ensure one turn at a time
            self.turnPageSemaphore.wait()

            Task {
                let currentRightPageIndex = await self.pageTurnState.currentRightPageIndex

                // Don't turn when reaching the start of the pages
                guard currentRightPageIndex > 1 else {
                    self.turnPageSemaphore.signal()
                    return
                }

                // Build the previous page first
                try? await self.addPreviousPage(frontImageURL: self.imageURLPairs[currentRightPageIndex - 2].0,
                                                backImageURL: self.imageURLPairs[currentRightPageIndex - 2].1,
                                                pageIndex: currentRightPageIndex - 2)

                // Turn the left page
                let indexToBeTurned = currentRightPageIndex - 1
                guard let entityToBeTurned = await self.pageTurnState.getPageEntity(index: indexToBeTurned) else {
                    self.turnPageSemaphore.signal()
                    return
                }

                // Add the rotationComponent to allow page rotation
                guard !entityToBeTurned.components.has(RotationComponent.self) else {
                    self.turnPageSemaphore.signal()
                    return
                }

                // Rotate to the targetAngle
                let rotationComponent = RotationComponent(targetAngle: 0 + Float(currentRightPageIndex) * 0.015, axis: [0, 0, -1])

                entityToBeTurned.components.set(rotationComponent)

                // Update the currenRightPageIndex
                await self.pageTurnState.updateCurrentRightPageIndex(to: currentRightPageIndex - 1)
            }
        }
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

    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
    private let imageWidth: Float
    private let imageHeight: Float
    private let imageURLPairs: [(URL?, URL?)]
    private let pageTurnState = PageTurnState()
    private let turnPageSemaphore = DispatchSemaphore(value: 1) // To ensure the memory efficiency, we turn 1 page at the time
    private let turnPageQueue = DispatchQueue(label: "turnPageQueue.IIIFVisionAR", attributes: .concurrent)
}

// MARK: - Build Entity Page from Images
extension CompoundEntity {
    private func addNextPage(frontImageURL: URL?, backImageURL: URL?, pageIndex: Int) async throws {
        // Skip building page if it existed
        guard await pageTurnState.getPageEntity(index: pageIndex) == nil else {
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
        await pageTurnState.cachePageEntity(index: pageIndex, entity: pageRootEntity)

        // Add to the Entity
        self.addChild(pageRootEntity)
        updateCollisionShape()
    }

    private func addPreviousPage(frontImageURL: URL?, backImageURL: URL?, pageIndex: Int) async throws {
        // Skip building page if it existed
        guard await pageTurnState.getPageEntity(index: pageIndex) == nil else {
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
        await pageTurnState.cachePageEntity(index: pageIndex, entity: pageRootEntity)

        // Add to the Entity
        self.addChild(pageRootEntity)
        updateCollisionShape()
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
