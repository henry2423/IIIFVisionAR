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
    let entityObject = CompoundEntity(width: 1.100, height: 1.418)
    let rootEntity = AnchorEntity(.plane(.horizontal, classification: .table, minimumBounds: [0, 0]), trackingMode: .once)

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
            content.add(rootEntity)

            // Load object on the anchorEntity
            try? await entityObject.addPreviousPage(frontImageURL: imageURLPages[leftPageIndex].0, backImageURL: imageURLPages[leftPageIndex].1)
            try? await entityObject.addNextPage(frontImageURL: imageURLPages[leftPageIndex + 1].0, backImageURL: imageURLPages[leftPageIndex + 1].1)
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

                            entityObject.turnToNextPage(value, pageNumber: leftPageIndex)

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

                            entityObject.turnToPreviousPage(value, pageNumber: leftPageIndex)

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
