//
//  CompoundImageRealityView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/21/23.
//

import SwiftUI
import RealityKit

struct CompoundImageRealityView: View {
    let entityObject = CompoundEntity(width: 2.261, height: 2.309)

    var body: some View {
        RealityView { content in
            try! await entityObject.setImages(leftFrontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!, rightFrontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!)
            // Position the object 2 meters in front of the user
            // with the bottom of the object touching the floor.
//            entityObject.position = SIMD3(0, 0, -2)
            content.add(entityObject)
        }
        .gesture(DragGesture()
            .targetedToEntity(entityObject)
            .onEnded { value in
                switch SwipeDirection.detectDirection(value: value.gestureValue) {
                case .left:
                    entityObject.handleSwipLeftGesture(value)
                case .right:
                    entityObject.handleSwipRightGesture(value)
                default:
                    break
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

