//
//  CompoundImageRealityView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import SwiftUI
import RealityKit

struct CompoundImageRealityView: View {
    let entityObject = CompoundEntity(width: 1.100, height: 1.418)
    let imageURLPages = [
        (nil, nil),
        (Bundle.main.url(forResource: "Love-1", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-2", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Love-3", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-4", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Love-5", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-6", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Love-7", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-8", withExtension: "jpg")!),
        (nil, nil),
    ]

    var body: some View {
        RealityView { content in
            try? await entityObject.addPreviousPage(frontImageURL: imageURLPages[leftPageIndex].0, backImageURL: imageURLPages[leftPageIndex].1)
            try? await entityObject.addNextPage(frontImageURL: imageURLPages[leftPageIndex + 1].0, backImageURL: imageURLPages[leftPageIndex + 1].1)
            entityObject.position = SIMD3(0, 0, -1)
            content.add(entityObject)
        }
        .gesture(TapGesture(count: 2)
            .targetedToAnyEntity()
            .onEnded { _ in
                isMovingObject.toggle()
            }
        )
        .gesture(DragGesture()
            .targetedToEntity(entityObject)
            .onChanged { value in
                if isMovingObject {
                    entityObject.handleDragGesture(value)
                }
            }
            .onEnded { value in
                if isMovingObject {
                    entityObject.handleDragGestureEnded()
                } else {
                    switch SwipeDirection.detectDirection(value: value.gestureValue) {
                    case .left:
                        guard !isLoading, leftPageIndex < imageURLPages.count - 2 else {
                            // Reach the end of the pages (exclude the virtual page)
                            return
                        }

                        isLoading = true
                        leftPageIndex += 1

                        Task {
                            // Load the next page if needed
                            if leftPageIndex + 1 < imageURLPages.count {
                                try? await entityObject.addNextPage(frontImageURL: imageURLPages[leftPageIndex + 1].0, backImageURL: imageURLPages[leftPageIndex + 1].1)
                            }

                            entityObject.turnToNextPage(value)

                            isLoading = false
                        }
                    case .right:
                        guard !isLoading, leftPageIndex > 0 else {
                            // Must have more than 1 page to turn back
                            return
                        }

                        isLoading = true
                        leftPageIndex -= 1

                        Task {
                            // Load the previous page if needed
                            if leftPageIndex >= 0 {
                                try? await entityObject.addPreviousPage(frontImageURL: imageURLPages[leftPageIndex].0, backImageURL: imageURLPages[leftPageIndex].1)
                            }

                            entityObject.turnToPreviousPage(value)

                            isLoading = false
                        }
                    default:
                        break
                    }
                }
            }
        )
        .gesture(RotateGesture()
            .targetedToEntity(entityObject)
            .onChanged { value in
                entityObject.handleRotationGesture(value)
            }
            .onEnded { _ in
                entityObject.handleRotationGestureEnded()
            }
        )
    }

    @State private var isLoading: Bool = false
    @State private var leftPageIndex = 0
    @State private var isMovingObject: Bool = false
}

enum SwipeDirection: String {
    case left, right, up, down, none

    static func detectDirection(value: DragGesture.Value) -> Self {
        if value.startLocation.x > value.location.x + 24 {
            return .left
        }
        if value.startLocation.x < value.location.x - 24 {
            return .right
        }
        if value.startLocation.y < value.location.y - 24 {
            return .down
        }
        if value.startLocation.y > value.location.y + 24 {
            return .up
        }
        return .none
    }
}


extension View {
    /// Listens for gestures and places an item based on those inputs.
    func placementGestures(
        initialPosition: Point3D = .zero
    ) -> some View {
        self.modifier(
            PlacementGesturesModifier(
                initialPosition: initialPosition
            )
        )
    }
}

/// A modifier that adds gestures and positioning to a view.
private struct PlacementGesturesModifier: ViewModifier {
    var initialPosition: Point3D

    @State private var scale: Double = 1
    @State private var startScale: Double? = nil
    @State private var position: Point3D = .zero
    @State private var startPosition: Point3D? = nil

    func body(content: Content) -> some View {
        content
            .onAppear {
                position = initialPosition
            }
            .scaleEffect(scale)
            .position(x: position.x, y: position.y)
            .offset(z: position.z)

            // Enable people to move the model anywhere in their space.
            .simultaneousGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
                .onChanged { value in
                    if let startPosition {
                        let delta = value.location3D - value.startLocation3D
                        position = startPosition + delta
                    } else {
                        startPosition = position
                    }
                }
                .onEnded { _ in
                    startPosition = nil
                }
            )

            // Enable people to scale the model within certain bounds.
            .simultaneousGesture(MagnifyGesture()
                .onChanged { value in
                    if let startScale {
                        scale = max(0.1, min(3, value.magnification * startScale))
                    } else {
                        startScale = scale
                    }
                }
                .onEnded { value in
                    startScale = scale
                }
            )
    }
}
