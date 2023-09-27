//
//  CompoundImageVolumetric.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 9/16/23.
//

import SwiftUI
import RealityKit
import IIIFImageEntity

struct CompoundImageVolumetric: View {
    let entityObject = CompoundImageEntity(width: 1.100, height: 1.418, imageURLPairs: [
        Bundle.main.url(forResource: "Love-1", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-2", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-3", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-4", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-5", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-6", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-7", withExtension: "jpg")!,
        Bundle.main.url(forResource: "Love-8", withExtension: "jpg")!,
    ].buildPagePairs())

    var body: some View {
        RealityView { content in
            try? await entityObject.loadInitialResource()
            entityObject.transform.translation = .init(x: 0, y: -1.418/2, z: 0)
            content.add(entityObject)
        }
        .gesture(DragGesture()
            .targetedToEntity(entityObject)
            .onEnded { value in
                switch PageSwipeDirection.detectDirection(value: value.gestureValue) {
                case .left:
                    entityObject.turnToNextPage()
                case .right:
                    entityObject.turnToPreviousPage()
                case .none:
                    break
                }
            }
        )
    }
}

extension VerticalAlignment {
    /// A custom alignment to center the control panel under the globe.
    private struct ControlPanelAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.bottom]
        }
    }

    /// A custom alignment guide to center the control panel under the globe.
    static let controlPanelGuide = VerticalAlignment(
        ControlPanelAlignment.self
    )
}
