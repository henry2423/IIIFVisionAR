//
//  CompoundEntity.swift
//
//
//  Created by Henry Huang on 8/21/23.
//

import Foundation
import AVFoundation
import RealityKit
import SwiftUI

actor PageTurnState {
    // MARK: currentRightPageIndex access

    func updateCurrentRightPageIndex(to newValue: Int) {
        currentRightPageIndex = newValue
    }

    private(set) var currentRightPageIndex = 1

    // MARK: pageIndexEntityDict access

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

public final class CompoundImageEntity: Entity {

    public required init(width: Float, height: Float, imageURLPairs: [(URL?, URL?)]) {
        self.imageWidth = width
        self.imageHeight = height
        self.imageURLPairs = imageURLPairs

        super.init()

        self.name = UUID().uuidString   // Setup for unique identifier for RotationSystem
        
        // Box Width = width * 2 (two pages)
        // Box Height = width (For page rotation)
        // Box Depth = height
        self.components.set(CollisionComponent(shapes: [.generateBox(size: .init(width * 2, width, height))]))

        #if os(visionOS) // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
        self.components.set(InputTargetComponent())
        #endif

        observeNotification()

        #if os(visionOS)
        configureSpatialAudioExperience()
        #endif

        setupSoundSystem()
    }

    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .rotationFinished, object: nil)
    }

    @objc func cleanupNonVisibleEntities(_ notification: Notification) {
        // Ensure the target entityName is self
        guard let entityName = notification.userInfo?["entityName"] as? String,
              entityName == self.name else {
            return
        }

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
    private var pageTurnSoundController: AudioPlaybackController?
}

// MARK: IIIFImageEntityProtocol

extension CompoundImageEntity: IIIFImageEntityProtocol {
    public func loadInitialResource() async throws {
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

    public func turnToNextPage() {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            // Lock the pageTurn action to ensure one turn at a time, don't pending too many in-flight page turn gesture
            guard turnPageSemaphore.wait(timeout: .now() + 1.0) == .success else {
                return
            }

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

                self.pageTurnSoundController?.play()

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

    public func turnToPreviousPage() {
        turnPageQueue.async { [weak self] in
            guard let self else { return }

            // Lock the pageTurn action to ensure one turn at a time, don't pending too many in-flight page turn gesture
            guard turnPageSemaphore.wait(timeout: .now() + 1.0) == .success else {
                return
            }

            Task {
                let currentRightPageIndex = await self.pageTurnState.currentRightPageIndex

                // Don't turn when reaching the start of the pages
                guard currentRightPageIndex > 1 else {
                    self.turnPageSemaphore.signal()
                    return
                }

                self.pageTurnSoundController?.play()

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

    #if os(visionOS) // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
    public func handleDragGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        let sourcePosition = sourcePosition ?? self.position
        self.sourcePosition = sourcePosition
        let delta = value.convert(value.translation3D, from: .local, to: .scene)
        // Only allow the object to be moved along the X- and Z-axis.
        self.position = sourcePosition + SIMD3(delta.x, 0, delta.z)
    }

    public func handleDragGestureEnded() {
        sourcePosition = nil
    }

    public func handleRotationGesture(_ value: EntityTargetValue<RotateGesture.Value>) {
        let sourceRotation = sourceRotation ?? self.transform.rotation
        self.sourceRotation = sourceRotation
        let delta = simd_quatf(angle: -Float(value.rotation.radians), axis: [0, 1, 0])
        self.transform.rotation = sourceRotation * delta
    }

    public func handleRotationGestureEnded() {
        sourceRotation = nil
    }
    #endif
}

// MARK: - Build Entity Page from Images

extension CompoundImageEntity {
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
            #if os(visionOS)    // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
            let resource = try await TextureResource(contentsOf: frontImageURL, options: .init(semantic: .color))
            #else
            let resource = try TextureResource.load(contentsOf: frontImageURL, options: .init(semantic: .color))
            #endif
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
            #if os(visionOS)    // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
            let resource = try await TextureResource(contentsOf: backImageURL, options: .init(semantic: .color))
            #else
            let resource = try TextureResource.load(contentsOf: backImageURL, options: .init(semantic: .color))
            #endif
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

// MARK: Sound System

extension CompoundImageEntity {
    private func setupSoundSystem() {
        if let pageTurnSoundResource = try? AudioFileResource.load(named: "pageTurnSound.wav", in: Bundle.module) {
            self.pageTurnSoundController = prepareAudio(pageTurnSoundResource)
        }
    }

    #if os(visionOS)
    /// Configures a person's intended Spatial Audio experience to best fit the presentation.
    /// - Parameter presentation: the requested player presentation.
    private func configureSpatialAudioExperience() {
        do {
            let experience: AVAudioSessionSpatialExperience = .headTracked(soundStageSize: .automatic, anchoringStrategy: .automatic)
            try AVAudioSession.sharedInstance().setIntendedSpatialExperience(experience)
        } catch {
            // TODO: Error handling
        }
    }
    #endif
}
