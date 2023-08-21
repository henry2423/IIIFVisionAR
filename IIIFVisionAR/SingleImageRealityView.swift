//
//  SingleImageRealityView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI
import RealityKit

struct SingleImageRealityView: View {
    @State var entityObject: InteractiveObject

    var body: some View {
        RealityView { content in
            // Position the object 2 meters in front of the user
            // with the bottom of the object touching the floor.
            entityObject.entity.position = SIMD3(0, 0, -2)
            content.add(entityObject.entity)
        }
        .gesture(DragGesture()
            .targetedToEntity(entityObject.entity)
            .onChanged { value in
                entityObject.handleDragGesture(value)
            }
            .onEnded { _ in
                entityObject.handleDragGestureEnded()
            }
        )
        .gesture(RotateGesture()
            .targetedToEntity(entityObject.entity)
            .onChanged { value in
                entityObject.handleRotationGesture(value)
            }
            .onEnded { _ in
                entityObject.handleRotationGestureEnded()
            }
        )
    }
}


