//
//  CompoundImageRealityView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import SwiftUI
import ARKit
import RealityKit
import IIIFImageEntity

struct CompoundImageRealityView: View {
    let entityObject: CompoundImageEntity
    let rootEntity = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: [0, 0]), trackingMode: .continuous)

    var body: some View {
        RealityView { content in
            content.add(rootEntity)

            try? await entityObject.loadInitialResource()

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
                        entityObject.turnToNextPage()
                    case .right:
                        entityObject.turnToPreviousPage()
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
