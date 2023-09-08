//
//  CompoundImageRealityView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import SwiftUI
import ARKit
import RealityKit

struct CompoundImageRealityView: View {
    let entityObject = CompoundEntity(width: 1.100, height: 1.418, imageURLPairs: [
        (nil, nil),
        (Bundle.main.url(forResource: "Love-1", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-2", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Love-3", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-4", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Love-5", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-6", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Love-7", withExtension: "jpg")!, Bundle.main.url(forResource: "Love-8", withExtension: "jpg")!),
        (nil, nil),
    ])
    let rootEntity = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: [0, 0]), trackingMode: .continuous)

    var body: some View {
        RealityView { content in
            content.add(rootEntity)

            try? await entityObject.loadInitialPages()

            // Add object on the anchorEntity
            rootEntity.addChild(entityObject)
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
                    switch PageSwipeDirection.detectDirection(value: value.gestureValue) {
                    case .left:
                        entityObject.turnToNextPage(value)
                    case .right:
                        entityObject.turnToPreviousPage(value)
                    case .none:
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

    @State private var isMovingObject: Bool = false
}

enum PageSwipeDirection: String {
    case left, right, none

    static func detectDirection(value: DragGesture.Value) -> Self {
        if value.startLocation3D.x > value.location3D.x + 24 {
            return .left
        }
        if value.startLocation3D.x < value.location3D.x - 24 {
            return .right
        }
        return .none
    }
}
