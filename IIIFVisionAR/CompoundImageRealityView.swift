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
    let imageURLPages = [
        (nil, nil),
        (Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!, Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!),
        (Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!, Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!),
        (nil, nil),
    ]
    @State private var leftPageIndex = 0

    var body: some View {
        RealityView { content in
            try? await entityObject.addPreviousPage(frontImageURL: imageURLPages[leftPageIndex].0, backImageURL: imageURLPages[leftPageIndex].1)
            try? await entityObject.addNextPage(frontImageURL: imageURLPages[leftPageIndex + 1].0, backImageURL: imageURLPages[leftPageIndex + 1].1)
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
                            try? await entityObject.addPreviousPage(frontImageURL: imageURLPages[leftPageIndex].0, backImageURL: imageURLPages[leftPageIndex].0)
                        }

                        entityObject.turnToPreviousPage(value)

                        isLoading = false
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

    @State private var isLoading: Bool = false
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

