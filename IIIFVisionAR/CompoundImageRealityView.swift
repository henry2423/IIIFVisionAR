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
    @State private var currentPageIndex = 0

    var body: some View {
        RealityView { content in
            try? await entityObject.addNextPage(frontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg"), backImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg"))
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
                    Task {
                        try? await entityObject.addNextPage(frontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg"), backImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg"))

                        entityObject.turnToNextPage(value)

                        currentPageIndex += 1
                    }
                case .right:
                    guard currentPageIndex >= 1 else {
                        // Must have more than 1 page to turn back
                        return
                    }

                    Task {
                        try? await entityObject.addPreviousPage(frontImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg"), backImageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg"))

                        entityObject.turnToPreviousPage(value)

                        currentPageIndex -= 1
                    }
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

