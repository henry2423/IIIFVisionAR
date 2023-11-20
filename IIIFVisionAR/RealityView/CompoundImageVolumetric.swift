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
    let entityObject: CompoundImageEntity
    let yOffset: Float
    let zOffset: Float

    var body: some View {
        RealityView { content in
            try? await entityObject.loadInitialResource()
            entityObject.transform.translation = .init(x: 0, y: yOffset, z: zOffset)
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
        .onDisappear {
            appState.closeIIIFItem()
        }
    }

    @Environment(AppState.self) private var appState
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
