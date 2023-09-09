//
//  SingleImageEntiy.swift
//  
//
//  Created by Henry Huang on 9/8/23.
//

import RealityKit
import SwiftUI

public final class SingleImageEntity: Entity {
    public required init(width: Float, height: Float, imageURL: URL) {
        self.imageWidth = width
        self.imageHeight = height
        self.imageURL = imageURL

        let planeMesh = MeshResource.generatePlane(width: width, depth: height)
        self.imageModelEntity = ModelEntity(mesh: planeMesh, materials: [])

        super.init()

        self.addChild(imageModelEntity)

        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))

        #if os(visionOS) // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
        self.components.set(InputTargetComponent())
        #endif
    }

    @available(*, unavailable)
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    private func updateCollisionShape() {
        let bounds = self.visualBounds(relativeTo: nil).extents
        self.components[CollisionComponent.self]?.shapes = [.generateBox(size: bounds)]
    }

    private let imageModelEntity: ModelEntity
    private let imageWidth: Float
    private let imageHeight: Float
    private let imageURL: URL
    private var sourcePosition: SIMD3<Float>?
    private var sourceRotation: simd_quatf?
}

// MARK: IIIFImageEntityProtocol

extension SingleImageEntity: IIIFImageEntityProtocol {
    public func loadInitialResource() async throws {
        var material = PhysicallyBasedMaterial()
        #if os(visionOS)    // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
        let resource = try await TextureResource(contentsOf: imageURL)
        #else
        let resource = try TextureResource.load(contentsOf: imageURL)
        #endif
        material.baseColor.texture = .init(resource)
        imageModelEntity.model?.materials = [material]
    }

    public func turnToNextPage() {
        // For single image, no need to turn page
    }

    public func turnToPreviousPage() {
        // For single image, no need to turn page
    }

    #if os(visionOS) // Progma Mark for visionOS https://developer.apple.com/documentation/visionos/bringing-your-app-to-visionos
    public func handleDragGesture(_ value: EntityTargetValue<DragGesture.Value>) {
        let sourcePosition = sourcePosition ?? self.position
        self.sourcePosition = sourcePosition
        let delta = value.convert(value.translation3D, from: .local, to: self.parent!)
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
