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
            entityObject.position = SIMD3(0, 0, -2)
            content.add(entityObject)
        }
        .gesture(DragGesture()
            .targetedToEntity(entityObject)
            .onChanged { value in
                entityObject.handleDragGesture(value)
            }
            .onEnded { _ in
                entityObject.handleDragGestureEnded()
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
