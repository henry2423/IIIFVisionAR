//
//  SingleImageRealityView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI
import RealityKit

struct SingleImageRealityView: View {
    let entityObject = SingleImageEntity(width: 2.261, height: 2.309)
    let rootEntity = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: [0, 0]), trackingMode: .once)

    var body: some View {
        RealityView { content in
            content.add(rootEntity)
            
            try? await entityObject.setImage(imageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!)
            rootEntity.addChild(entityObject)
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


